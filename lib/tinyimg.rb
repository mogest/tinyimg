require_relative '../ext/tinyimg/tinyimg'

class Tinyimg
  attr_reader :width, :height

  private_class_method :new

  def self.from_file(filename)
    new(:filename, filename)
  end

  def self.from_io(io)
    from_string(io.read)
  end

  def self.from_string(data)
    new(:string, data)
  end

  def dimensions
    [width, height]
  end

  def resize(*args)
    dup.resize!(*args)
  end

  def resize!(*args)
    case args.map(&:class)
    when [Fixnum, Fixnum]
      resize_exact!(*args)
    when [Hash]
      width, height = convert_hash_to_exact_dimensions(args.first)
      resize_exact!(width, height)
    else
      raise ArgumentError, "#resize and #resize! accept either (width, height) or a hash with :width and/or :height keys"
    end
  end

  def resize_exact(width, height)
    dup.resize_exact!(width, height)
  end

  # Implemented in C
  # def resize_exact!(width, height)
  # end

  def resize_to_fit(new_width, new_height)
    dup.resize_to_fit!(new_width, new_height)
  end

  def resize_to_fit!(new_width, new_height)
    resize_to_fit_or_fill!(new_width, new_height) do |old_ratio, new_ratio|
      old_ratio > new_ratio
    end
  end

  def resize_to_fill(new_width, new_height)
    dup.resize_to_fill!(new_width, new_height)
  end

  def resize_to_fill!(new_width, new_height)
    resize_to_fit_or_fill!(new_width, new_height) do |old_ratio, new_ratio|
      old_ratio < new_ratio
    end
  end

  def save(filename)
    if respond_to?(:save_to_file)
      save_to_file(filename)
    else
      data = case determine_by_extension(filename)
             when :jpeg then to_jpeg
             when :png  then to_png
             end

      File.write(filename, data)
    end

    self
  end

  # Implemented in C
  # def to_jpeg(quality = DEFAULT_JPEG_QUALITY)
  # end

  # Implemented in C
  # def to_png(compression = nil)
  # end

  private

  def initialize(mode, data, type = nil)
    case mode
    when :string
      load_from_string(data, determine_type(data))
    when :filename
      if respond_to?(:load_from_file)
        load_from_file(data)
      else
        content = File.read(data)
        load_from_string(content, determine_type(content))
      end
    else
      raise
    end
  end

  def resize_to_fit_or_fill!(new_width, new_height)
    old_ratio = width / height.to_f
    new_ratio = new_width / new_height.to_f

    if yield(old_ratio, new_ratio)
      resize_width = new_width
      resize_height = (height * (new_width / width.to_f)).to_i
    else
      resize_width = (width * (new_height / height.to_f)).to_i
      resize_height = new_height
    end

    resize_exact!(resize_width, resize_height)
  end

  def determine_type(data)
    if data[0, 3].unpack("C*") == [255, 216, 255]
      :jpeg
    elsif data[0, 8].unpack("C*") == [137, 80, 78, 71, 13, 10, 26, 10]
      :png
    else
      raise ArgumentError, "Only JPEG and PNG files are supported"
    end
  end

  def determine_by_extension(filename)
    case filename.split(".").last.to_s.downcase
    when 'jpeg', 'jpg' then :jpeg
    when 'png'         then :png
    else
      raise ArgumentError, "Cannot determine image type based on the filename"
    end
  end

  def convert_hash_to_exact_dimensions(opts)
    if opts.empty? || !(opts.keys - [:width, :height]).empty?
      raise ArgumentError, "expected either :width or :height or both keys"
    end

    if opts.values.any? { |v| !v.is_a?(Fixnum) }
      raise ArgumentError, ":width and :height values must be integers"
    end

    new_width, new_height = opts[:width], opts[:height]

    if new_height.nil?
      new_height = height * new_width / width
    elsif new_width.nil?
      new_width = width * new_height / height
    end

    [new_width, new_height]
  end

  # Implemented in C
  # def load_from_string(data, type)
  # end

  # Implemented in C
  # Only available with libgd 2.1.1+
  # def load_from_file(filename)
  # end

  # Implemented in C
  # Only available with libgd 2.1.1+
  # def save_to_file(filename)
  # end
end
