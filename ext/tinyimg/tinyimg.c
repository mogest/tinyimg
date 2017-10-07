#include <ruby.h>
#include <gd.h>

VALUE get_error_class(VALUE self)
{
  return rb_const_get_at(rb_class_of(self), rb_intern("Error"));
}

gdImagePtr get_image_data(VALUE self)
{
  gdImagePtr image;
  VALUE wrapped_image = rb_iv_get(self, "@data");
  Data_Get_Struct(wrapped_image, struct gdImageStruct, image);
  return image;
}

void set_image_data(VALUE self, gdImagePtr image)
{
  VALUE klass, value;

  klass = rb_const_get_at(rb_class_of(self), rb_intern("Image"));
  value = Data_Wrap_Struct(klass, 0, gdImageDestroy, image);
  rb_iv_set(self, "@data", value);
}

void set_alpha(gdImagePtr image)
{
#ifdef HAVE_GDIMAGEALPHABLENDING
  gdImageAlphaBlending(image, 0);
  gdImageSaveAlpha(image, 1);
#endif
}

VALUE retrieve_image_dimensions(VALUE self)
{
  gdImagePtr image = get_image_data(self);

  rb_iv_set(self, "@width", INT2FIX(gdImageSX(image)));
  rb_iv_set(self, "@height", INT2FIX(gdImageSY(image)));

  return Qnil;
}

VALUE load_from_string(VALUE self, VALUE input, VALUE type)
{
  gdImagePtr image;
  ID type_id;
  long input_length;

  Check_Type(input, T_STRING);
  Check_Type(type, T_SYMBOL);
  type_id = SYM2ID(type);

  input_length = RSTRING_LEN(input);
  if (input_length >= 1L << 31) {
    rb_raise(get_error_class(self), "input must be less than 2GB in length");
  }

  if (type_id == rb_intern("png")) {
    image = gdImageCreateFromPngPtr((int)input_length, RSTRING_PTR(input));
  }
  else if (type_id == rb_intern("jpeg")) {
    image = gdImageCreateFromJpegPtr((int)input_length, RSTRING_PTR(input));
  }
  else {
    rb_raise(get_error_class(self), "type must be a supported image type");
  }

  if (!image) {
    rb_raise(get_error_class(self), "Error loading image data");
  }

  set_image_data(self, image);
  set_alpha(image);

  retrieve_image_dimensions(self);

  return self;
}

#ifdef HAVE_GDIMAGECREATEFROMFILE
VALUE load_from_file(VALUE self, VALUE filename)
{
  gdImagePtr image;

  Check_Type(filename, T_STRING);

  image = gdImageCreateFromFile(StringValueCStr(filename));
  if (!image) {
    rb_raise(get_error_class(self), "Error loading image data");
  }

  set_image_data(self, image);
  set_alpha(image);

  retrieve_image_dimensions(self);

  return self;
}
#endif

VALUE initialize_copy(int argc, VALUE *argv, VALUE self)
{
  gdImagePtr image, original;

  rb_call_super(argc, argv);

  original = get_image_data(self);

#ifdef HAVE_GDIMAGECLONE
  image = gdImageClone(original);
#else
  int width = gdImageSX(original), height = gdImageSY(original);

  image = gdImageCreateTrueColor(width, height);
  set_alpha(image);

  gdImageCopy(image, original, 0, 0, 0, 0, width, height);
#endif

  set_image_data(self, image);

  return Qnil;
}

#ifdef HAVE_GDIMAGEFILE
VALUE save_to_file(VALUE self, VALUE filename)
{
  gdImagePtr image;
  int result;

  Check_Type(filename, T_STRING);

  image = get_image_data(self);
  result = gdImageFile(image, StringValueCStr(filename));

  if (result == GD_FALSE) {
    rb_raise(get_error_class(self), "Unknown error occurred while trying to save the file; check it is using a known filename");
  }

  return self;
}
#endif

VALUE to_jpeg(int argc, VALUE *argv, VALUE self)
{
  gdImagePtr image;
  char *image_data;
  int size, quality;
  VALUE quality_value;

  rb_scan_args(argc, argv, "01", &quality_value);

  if (NIL_P(quality_value)) {
    quality = -1;
  }
  else {
    Check_Type(quality_value, T_FIXNUM);
    quality = FIX2INT(quality_value);
  }

  if (quality < -1 || quality > 100) {
    rb_raise(get_error_class(self), "Quality must be between 0 and 100, or -1 for default");
  }

  image = get_image_data(self);

  image_data = (char *) gdImageJpegPtr(image, &size, quality);
  if (!image_data) {
    rb_raise(get_error_class(self), "Unknown error occurred while trying to build a JPEG");
  }

  VALUE output = rb_str_new(image_data, size);
  gdFree(image_data);
  return output;
}

VALUE to_png(int argc, VALUE *argv, VALUE self)
{
  gdImagePtr image;
  char *image_data;
  int size;
  VALUE compression_value;
  int compression;

  rb_scan_args(argc, argv, "01", &compression_value);

  image = get_image_data(self);

  if (NIL_P(compression_value)) {
    image_data = (char *) gdImagePngPtr(image, &size);
  }
  else {
    Check_Type(compression_value, T_FIXNUM);
    compression = FIX2INT(compression_value);

    if (compression < 0 || compression > 9) {
      rb_raise(get_error_class(self), "Compression must be between 0 and 9");
    }

#ifdef HAVE_GDIMAGEPNGPTREX
    image_data = (char *) gdImagePngPtrEx(image, &size, compression);
#else
    image_data = (char *) gdImagePngPtr(image, &size);
#endif
  }

  if (!image_data) {
    rb_raise(get_error_class(self), "Unknown error occurred while trying to build a PNG");
  }

  VALUE output = rb_str_new(image_data, size);
  gdFree(image_data);
  return output;
}

VALUE resize_exact_bang(VALUE self, VALUE width_value, VALUE height_value)
{
  gdImagePtr image_in, image_out;
  int width, height;

  Check_Type(width_value, T_FIXNUM);
  Check_Type(height_value, T_FIXNUM);

  width = FIX2INT(width_value);
  height = FIX2INT(height_value);

  if (width <= 0 || height <= 0) {
    rb_raise(get_error_class(self), "width and height must both be positive integers");
  }

  image_in = get_image_data(self);
  image_out = gdImageCreateTrueColor(width, height);
  set_alpha(image_out);

  gdImageCopyResampled(
      image_out, image_in, 0, 0, 0, 0,
      gdImageSX(image_out), gdImageSY(image_out),
      gdImageSX(image_in), gdImageSY(image_in)
  );

  set_image_data(self, image_out);

  retrieve_image_dimensions(self);

  return self;
}

VALUE fill_transparent_color_bang(VALUE self, VALUE red_value, VALUE green_value, VALUE blue_value)
{
  gdImagePtr image_in, image_out;
  int red, green, blue;
  int color;

  Check_Type(red_value, T_FIXNUM);
  Check_Type(green_value, T_FIXNUM);
  Check_Type(blue_value, T_FIXNUM);

  red = FIX2INT(red_value);
  green = FIX2INT(green_value);
  blue = FIX2INT(blue_value);

  if (red < 0 || green < 0 || blue < 0 || red > 255 || green > 255 || blue > 255) {
    rb_raise(get_error_class(self), "red, green and blue must be integers between 0 and 255");
  }

  image_in = get_image_data(self);
  image_out = gdImageCreateTrueColor(gdImageSX(image_in), gdImageSY(image_in));

  color = gdImageColorAllocate(image_out, red, green, blue);
  gdImageFilledRectangle(image_out, 0, 0, gdImageSX(image_in), gdImageSY(image_in), color);

  gdImageCopy(
      image_out, image_in, 0, 0, 0, 0,
      gdImageSX(image_in), gdImageSY(image_in)
  );

  set_image_data(self, image_out);

  return self;
}

VALUE internal_crop_bang(VALUE self, VALUE x_value, VALUE y_value, VALUE width_value, VALUE height_value)
{
  gdImagePtr image_in, image_out;
  int x, y, width, height;

  Check_Type(x_value, T_FIXNUM);
  Check_Type(y_value, T_FIXNUM);
  Check_Type(width_value, T_FIXNUM);
  Check_Type(height_value, T_FIXNUM);

  x = FIX2INT(x_value);
  y = FIX2INT(y_value);
  width = FIX2INT(width_value);
  height = FIX2INT(height_value);

  if (x < 0 || y < 0) {
    rb_raise(get_error_class(self), "x, y must both be zero or positive integers");
  }

  if (width <= 0 || height <= 0) {
    rb_raise(get_error_class(self), "width and height must both be positive integers");
  }

  image_in = get_image_data(self);

  if (x + width > gdImageSX(image_in)) {
    rb_raise(get_error_class(self), "x + width is greater than the original image's width");
  }

  if (y + height > gdImageSY(image_in)) {
    rb_raise(get_error_class(self), "y + height is greater than the original image's height");
  }

  image_out = gdImageCreateTrueColor(width, height);
  set_alpha(image_out);

  gdImageCopy(image_out, image_in, 0, 0, x, y, width, height);

  set_image_data(self, image_out);

  retrieve_image_dimensions(self);

  return self;
}

void Init_tinyimg()
{
  VALUE cTinyimg = rb_define_class("Tinyimg", rb_cObject);
  rb_define_class_under(cTinyimg, "Image", rb_cObject);
  rb_define_class_under(cTinyimg, "Error", rb_const_get(rb_cObject, rb_intern("StandardError")));

  rb_define_method(cTinyimg, "resize_exact!", resize_exact_bang, 2);
  rb_define_method(cTinyimg, "fill_transparent_color!", fill_transparent_color_bang, 3);
  rb_define_method(cTinyimg, "to_jpeg", to_jpeg, -1);
  rb_define_method(cTinyimg, "to_png", to_png, -1);
  rb_define_private_method(cTinyimg, "initialize_copy", initialize_copy, -1);
  rb_define_private_method(cTinyimg, "load_from_string", load_from_string, 2);
  rb_define_private_method(cTinyimg, "retrieve_image_dimensions", retrieve_image_dimensions, 0);
  rb_define_private_method(cTinyimg, "internal_crop!", internal_crop_bang, 4);
#ifdef HAVE_GDIMAGECREATEFROMFILE
  rb_define_private_method(cTinyimg, "load_from_file", load_from_file, 1);
#endif
#ifdef HAVE_GDIMAGEFILE
  rb_define_private_method(cTinyimg, "save_to_file", save_to_file, 1);
#endif
}
