
module Confabulator
    class ImageAction
    	

    	def initialize(image, options)
            @options = options
            @resolution = "#{options[:width]}x#{options[:height]}"
            @options[:resolution] = @resolution  # add the conversion resolution to the options
            @image = image

            path = File.dirname(image.path.gsub("\\", "/"))
            name = File.basename(image.path.gsub("\\", "/"), '.*')
            
            @complete = false

            # avoid name clashes between posters and the original file when
            # transcoding the original
            if is_poster?
                @outputname = "#{File.join(path, name)}_#{@resolution}.#{options[:extension]}"
            else
                @outputname = "#{File.join(path, name)}_#{@resolution}_media.#{options[:extension]}"
            end
        end


        attr_accessor :store

        attr_reader :complete    # Has been transcoded?
        attr_reader :outputname  # filename
        attr_reader :resolution  # resolution
        attr_reader :options     # mime
        

        def is_poster?
            @options[:poster]
        end

    	def transcode
            @image.transcode(@outputname, "-resize #{@resolution}")
            @complete = true
    	end
    end
end
