
module Confabulator
    class Action
    	

    	def initialize(video, options)
            @options = options
            @resolution = "#{options[:width]}x#{options[:height]}"
            @video = video

            path = File.dirname(video.path.gsub("\\", "/"))
            name = File.basename(video.path.gsub("\\", "/"), '.*')
            
            @complete = false

            @poster = !!@options[:poster]
            if is_poster?
                @outputname = "#{File.join(path, name)}_#{@resolution}.jpg"
                @options[:mime] = 'image/jpeg'
            else
                @outputname = "#{File.join(path, name)}_#{@resolution}.#{options[:extension]}"
            end
        end


        attr_accessor :store

        attr_reader :complete    # Has been transcoded?
        attr_reader :outputname  # filename
        attr_reader :resolution  # resolution
        attr_reader :options     # mime
        

        def is_poster?
            @poster
        end

    	def transcode(thread)
            @thread = thread
            @worker = @thread.defer

            @thread.work(method(:do_work)).then(proc { |result|
                @worker.resolve(result)
            }, proc { |err|
                @worker.reject(err)
            })

            @worker.promise
    	end


        protected


        def do_work
            if @poster
                @video.screenshot(@outputname, seek_time: @options[:poster], resolution: @resolution)
            else
                @video.transcode(@outputname, @options) do |progress|
                    #method called with progress
                    @worker.notify progress
                end
                @complete = true
            end
            self
        end
    end
end
