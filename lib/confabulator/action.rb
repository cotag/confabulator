
module Confabulator
    class Action
    	

    	def initialize(video, options)
            @options = options
            @resolution = "#{options[:width]}x#{options[:height]}"
            @video = video
            @outputname = "#{video.path}_#{@resolution}.#{options[:extension]}"
        end


    #resolution
    #filename
    #remux or re-encode
    #output filename

    	


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
        end
    end
end
