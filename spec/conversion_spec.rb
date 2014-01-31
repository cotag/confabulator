require 'confabulator'


describe Confabulator::Configuration do
	before :each do
		@loop = Libuv::Loop.new
		@general_failure = []
		@timeout = @loop.timer do
			@loop.stop
			@general_failure << "test timed out"
		end
		@timeout.start(40000)
	end

	after :each do
	end
	
	describe '#generate_actions' do
		it "should generate transcode action we need to perform" do
			file_name = File.expand_path("../Video021.mp4", __FILE__)

			@loop.run { |logger|
				# expecing this to fail
				config = Confabulator::Configuration.new(@loop)
				config.check(file_name).then(proc { |res|
					@actions = res
					@loop.stop
				}, proc {
					@loop.stop
				})
			}

			expect(@general_failure).to eq([])
			expect(@actions.length).to eq(2)
		end

	end
end
