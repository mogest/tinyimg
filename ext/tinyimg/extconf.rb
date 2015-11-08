require 'mkmf'

def filter_dirs(dirs)
  dirs.select {|dir| Dir.exists?(dir)}
end

def cannot_find_gd
  abort <<-TEXT
*******************************************************************************
  It looks like libgd is not installed on your system.

  If you're on OS X, install homebrew and try
    brew install libgd

  If you're on Debian/Ubuntu linux, try
    apt-get install libgd-dev
*******************************************************************************
  TEXT
end

header_dirs = %w(/opt/local/include /usr/local/include /usr/include)
lib_dirs    = %w(/opt/local/lib /usr/local/lib /usr/lib)

dir_config('gd', filter_dirs(header_dirs), filter_dirs(lib_dirs))

have_library('gd', 'gdFree') or cannot_find_gd
have_header('gd.h')          or cannot_find_gd
have_func('gdImageJpegPtr')  or abort "Your libgd is too old!  You need at least version 1.8.0, and preferably 2.1.1+."
have_func('gdImageFile')
have_func('gdImageCreateFromFile')
have_func('gdImageAlphaBlending')
have_func('gdImageClone')
have_func('gdImagePngPtrEx')

create_makefile 'tinyimg/tinyimg'
