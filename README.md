# Tinyimg

Load a JPEG or PNG, get its dimensions, resize it, and extract it again as either a JPEG or PNG.

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

    image = Tinyimg.from_string(an_image_that_is_already_loaded)
    image = Tinyimg.from_file("some_image.png")
    image = Tinyimg.from_io(params[:uploaded_file])

Manipulate it by using one of the resize commands:

    image.resize_to_fit!(100, 100)  # image will be 100x100 maximum
    image.resize_to_fill!(100, 100) # image will be 100x100 minimum
    image.resize!(100, 100)         # forces image to be exactly 100x100

Then get an image back:

    image.to_png                 # returns a string
    image.to_jpeg                # returns a string
    image.save("some_image.jpg") # file type auto-determined by extension

You can ask for the image's dimensions:

    image.width       # => 120
    image.height      # => 80
    image.dimensions  # => [120, 80]

You can also use the non-! versions of the resize methods: `resize`, `resize_to_fit` and `resize_to_fill`.
These create a new image in memory and return it, leaving the old image untouched.  This is useful if you want
to resize an original image to multiple sizes.  Using these methods will take more memory.

## Examples

Take an uploaded file, save the original as a JPEG, then resize to create a thumbnail and save that too:

    Tinyimg
      .from_io(params[:uploaded_file])
      .save("#{path}/full_size.jpg")
      .resize_to_fit!(100, 100)
      .save("#{path}/thumbnail.jpg")

Load a file from disk, make a thumbnail, and return it as a JPEG so we can save it into our database:

    data = Tinyimg.from_file(image_filename).resize_to_fit!(100, 100).to_jpeg
    user.update!(thumbnail_image: data)

## Author and licence

Copyright 2015 Roger Nesbitt.  Licenced under the MIT licence.
