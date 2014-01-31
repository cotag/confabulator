require 'confabulator'


describe Confabulator::Configuration do
	before :each do
		@loop = Libuv::Loop.new
		@general_failure = []
		@timeout = @loop.timer do
			@loop.stop
			@general_failure << "test timed out"
		end
		@timeout.start(5000)
	end

	after :each do
	end
	
	describe '#generate_actions' do
		it "should generate transcode action we need to perform" do
			@loop.run { |logger|
				# expecing this to fail
			}

			expect(@general_failure).to eq([])
			#res = @klass.check
			#expect(res[0]).to eq(true)
			#expect(res[1]).to eq(true)
			#expect(res[2]).to eq('hello')
		end

		it "should error on being handed an invalid video" do


		end

		it "should generate the correct number of video outputs for a 1080p input" do


		end

	end
end
