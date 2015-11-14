# Tinyimg

Load a JPEG or PNG, get its dimensions, crop it, resize it, and extract it again as either a JPEG or PNG.

This gem can work from image data stored in memory, as well as from a file or IO stream.
It's been coded to be as efficient as possible, so doesn't use temporary files.

Tinyimg uses libgd for its image processing.  libgd is significantly less painful to install than
ImageMagick and friends!  Other than that, all that is required is Ruby 2.0+.

## Installation

If you don't already have libgd installed on your system, install it.

On OS X, install Homebrew and

    brew install libgd

On a Linux system, use your package manager.  For example, on Debian/Ubuntu:

    sudo apt-get install libgd-dev

Then add tinyimg to your project's Gemfile

    gem 'tinyimg'

## Usage

Load the image with the method that fits your use case:

```ruby
image = Tinyimg.from_string(an_image_that_is_already_loaded)
image = Tinyimg.from_file("some_image.png")
image = Tinyimg.from_io(params[:uploaded_file])
```

Resize it by using one of these methods:

```ruby
image.resize_exact!(100, 100)   # forces image to be exactly 100x100
image.resize!(width: 100)       # width = 100 and aspect ratio maintained
image.resize!(height: 50)       # height = 50 and aspect ratio maintained
image.resize_to_fit!(100, 100)  # image will be 100x100 maximum
image.resize_to_fill!(100, 100) # image will be 100x100 minimum
```

Crop it using this method:

```ruby
# Crops the image from (20, 20) to (70, 70), resulting in a 50x50 image.
image.crop!(x: 20, y: 20, width: 50, height: 50)

# By default, x and y arguments are zero, and width and height arguments
# are the width and height of the original image.
image.crop!(width: image.height)
```

Then get an image back:

```ruby
image.to_png                 # returns a string
image.to_jpeg                # returns a string
image.save("some_image.jpg") # file type auto-determined by extension
```

You can ask for the image's dimensions:

```ruby
image.width       # => 120
image.height      # => 80
image.dimensions  # => [120, 80]
```

You can also use the non-! versions of the operation methods: `resize_exact`, `resize`, `resize_to_fit`, `resize_to_fill` and `crop`.
These create a new image in memory and return it, leaving the old image untouched.  This is useful if you want
to resize an original image to multiple sizes.  Using these methods will take more memory.

## Examples

Take an uploaded file that's a PNG or JPEG, save the original as a JPEG, then resize to create a thumbnail and save that too:

```ruby
Tinyimg
  .from_io(params[:uploaded_file])
  .save("#{path}/full_size.jpg")
  .resize_to_fit!(100, 100)
  .save("#{path}/thumbnail.jpg")
```

Load a file from disk, make a thumbnail, and return it as a JPEG so we can save it into our database:

```ruby
data = Tinyimg.from_file(image_filename).resize_to_fit!(100, 100).to_jpeg
user.update!(thumbnail_image: data)
```

## Author and licence

Copyright 2015 Roger Nesbitt.  Licenced under the MIT licence.
