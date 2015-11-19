require 'tinyimg'

RSpec.describe Tinyimg do
  let(:samples_directory) { "#{File.dirname(__FILE__)}/samples" }
  let(:sample_filename) { "#{samples_directory}/duck.png" }
  let(:sample) { Tinyimg.from_file(sample_filename) }

  let(:tmp_directory) { "#{File.dirname(__FILE__)}/tmp" }
  let(:tmp_jpg_filename)  { "#{tmp_directory}/test.jpg" }
  let(:tmp_png_filename)  { "#{tmp_directory}/test.png" }

  describe "#from_file, #width, #height and #dimensions" do
    it "loads from a file and returns the width and height of the image" do
      expect(sample.width).to eq 200
      expect(sample.height).to eq 153
      expect(sample.dimensions).to eq [200, 153]
    end
  end

  describe "#from_string" do
    it "loads a PNG" do
      image = Tinyimg.from_string(IO.read(sample_filename))
      expect(image.dimensions).to eq [200, 153]
    end
  end

  describe "#from_io" do
    it "loads a PNG" do
      File.open(sample_filename, "r") do |file|
        image = Tinyimg.from_io(file)
        expect(image.dimensions).to eq [200, 153]
      end
    end
  end

  describe "#resize_exact" do
    it "resizes the image as requested, creating a new image" do
      result = sample.resize_exact(100, 100)
      expect(result).to_not eql sample
      expect(sample.dimensions).to eq [200, 153]
      expect(result.dimensions).to eq [100, 100]
    end
  end

  describe "#resize_exact!" do
    it "resizes the image as requested" do
      result = sample.resize_exact!(100, 100)
      expect(result).to eql sample
      expect(sample.dimensions).to eq [100, 100]
    end
  end

  describe "#resize" do
    it "takes an exact width and height and resizes" do
      result = sample.resize(100, 100)
      expect(result.dimensions).to eq [100, 100]
    end

    it "takes a width and height as a hash and resizes" do
      result = sample.resize(width: 100, height: 100)
      expect(result.dimensions).to eq [100, 100]
    end

    it "takes just a width and resizes, calculating the height" do
      result = sample.resize(width: 100)
      expect(result.dimensions).to eq [100, 76]
    end

    it "takes just a height and resizes, calculating the width" do
      result = sample.resize(height: 100)
      expect(result.dimensions).to eq [130, 100]
    end
  end

  describe "#resize!" do
    it "takes an exact width and height and resizes" do
      result = sample.resize!(100, 100)
      expect(sample.dimensions).to eq [100, 100]
    end

    it "takes a width and height as a hash and resizes" do
      result = sample.resize!(width: 100, height: 100)
      expect(sample.dimensions).to eq [100, 100]
    end

    it "takes just a width and resizes, calculating the height" do
      result = sample.resize!(width: 100)
      expect(sample.dimensions).to eq [100, 76]
    end

    it "takes just a height and resizes, calculating the width" do
      result = sample.resize!(height: 100)
      expect(sample.dimensions).to eq [130, 100]
    end

    it "raises if other keys are provided" do
      expect { sample.resize!(something: 123) }.to raise_error(Tinyimg::Error)
    end

    it "raises if non-integer values are provided" do
      expect { sample.resize!(width: "123") }.to raise_error(Tinyimg::Error)
    end

    it "raises if no keys are provided" do
      expect { sample.resize! }.to raise_error(Tinyimg::Error)
    end

    it "raises if only one argument is provided" do
      expect { sample.resize!(123) }.to raise_error(Tinyimg::Error)
    end
  end

  describe "#resize_to_fit!" do
    it "calculates the image dimensions so it fits the width and resizes" do
      sample.resize_to_fit!(100, 100)
      expect(sample.dimensions).to eq [100, 76]
    end

    it "calculates the image dimensions so it fits the height and resizes" do
      sample.resize_to_fit!(1000, 100)
      expect(sample.dimensions).to eq [130, 100]
    end
  end

  describe "#resize_to_fill!" do
    it "calculates the image dimensions so it fills the width and resizes" do
      sample.resize_to_fill!(1000, 100)
      expect(sample.dimensions).to eq [1000, 765]
    end

    it "calculates the image dimensions so it fills the height and resizes" do
      sample.resize_to_fill!(100, 100)
      expect(sample.dimensions).to eq [130, 100]
    end
  end

  describe "#crop" do
    it "crops the image to the specified size and offset" do
      result = sample.crop(x: 10, y: 20, width: 30, height: 40)
      expect(result.dimensions).to eq [30, 40]
    end
  end

  describe "#crop!" do
    it "crops the image to the specified size and offset" do
      sample.crop!(x: 10, y: 20, width: 30, height: 40)
      expect(sample.dimensions).to eq [30, 40]
    end

    it "defaults x and y to zero and width and height to the original width and height" do
      sample.crop!
      expect(sample.dimensions).to eq [200, 153]
    end

    it "raises if the requested area is not inside the original image" do
      expect { sample.crop!(x: 10, y: 20, width: 195, height: 40) }.to raise_error(Tinyimg::Error)
      expect { sample.crop!(x: 10, y: 20, width: 95, height: 140) }.to raise_error(Tinyimg::Error)
      expect { sample.crop!(width: 95, height: 160) }.to raise_error(Tinyimg::Error)
    end
  end

  describe "#save" do
    it "saves a JPEG" do
      begin
        sample.save(tmp_jpg_filename)
        expect(File.read(tmp_jpg_filename, 3).unpack("C*")).to eq [255, 216, 255]

        reloaded = Tinyimg.from_file(tmp_jpg_filename)
        expect(reloaded.dimensions).to eq [200, 153]
      ensure
        File.unlink(tmp_jpg_filename)
      end
    end

    it "saves a PNG" do
      begin
        sample.save(tmp_png_filename)
        expect(File.read(tmp_png_filename, 3).unpack("C*")).to eq [137, 80, 78]

        reloaded = Tinyimg.from_file(tmp_png_filename)
        expect(reloaded.dimensions).to eq [200, 153]
      ensure
        File.unlink(tmp_png_filename)
      end
    end
  end

  describe "#to_jpeg" do
    it "exports a JPEG" do
      data = sample.to_jpeg
      expect(data[0, 3].unpack("C*")).to eq [255, 216, 255]

      reloaded = Tinyimg.from_string(data)
      expect(reloaded.dimensions).to eq [200, 153]
    end
  end

  describe "#to_png" do
    it "exports a PNG" do
      data = sample.to_png
      expect(data[0, 3].unpack("C*")).to eq [137, 80, 78]

      reloaded = Tinyimg.from_string(data)
      expect(reloaded.dimensions).to eq [200, 153]
    end
  end
end
