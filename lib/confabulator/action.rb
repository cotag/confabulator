
module Confabulator
    class Action
    	

    	def initialize(video, options)
            @options = options
            @resolution = "#{options[:width]}x#{options[:height]}"
            @video = video

            path = File.dirname(video.path.gsub("\\", "/"))
            name = File.basename(video.path.gsub("\\", "/"), '.*')
            @outputname = "#{File.join(path, name)}_#{@resolution}.#{options[:extension]}"
            @complete = false
        end


        attr_reader :complete    # Has been transcoded?
        attr_reader :outputname  # filename
        attr_reader :resolution  # resolution
        attr_reader :options     # mime

        attr_accessor :store


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
            @video.transcode(@outputname, @options) do |progress|
                #method called with progress
                @worker.notify progress
            end
            @complete = true
            self
        end
    end
end
