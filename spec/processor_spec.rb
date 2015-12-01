require 'spec_helper'

describe PgStream::Processor do
  let(:stream) { instance_double('PgStream::Stream') }
  let(:row) { ['test@example.com', '1234567'] }
  let(:fields) { ['email', 'id']  }
  let(:stream_processor) { PgStream::Processor.new(stream) }

  before do
    allow(stream).to receive(:each_row).and_yield(row).and_yield(row)
  end

  describe '#register' do
    it "it adds the passed lambda to the processor's callbacks" do
      callbacks = stream_processor.register(before_execute: -> { puts 'Hold on to your butts!!!' })
      expect(callbacks[:before_execute].length).to eq(1)
    end

    it 'raises an error if the callback is not of an acceptable type' do
      expect { stream_processor.register(after_dinner: -> { puts 'Eat dessert' }) }.to raise_error(RuntimeError)
    end
  end

  describe '#execute' do
    let(:result_collector) { [] }

    context 'when there are callbacks registered' do
      before do
        stream_processor.register(before_execute: lambda do
          @before_time = Time.now
        end
        )
        stream_processor.register(during_execute: lambda do |_row, _row_count|
          @during_time = Time.now
        end
        )
        stream_processor.register(after_execute: ->(_row_count) { @after_time = Time.now } )
      end

      it "first calls 'before_execute' callbacks" do
        stream_processor.execute
        expect(@before_time < @during_time).to be_truthy
      end

      it "then calls 'during_execute' callbacks, then 'after_execute' callbacks" do
        stream_processor.execute
        expect(@during_time < @after_time).to be_truthy
      end
    end

    context 'if a callback counts during_execute calls' do
      before do
        stream_processor.register(before_execute: lambda do
         @call_counts = 0
        end
        )
        stream_processor.register(during_execute: lambda do |_row, _row_count|
         @call_counts += 1
        end
        )
      end

      it 'calls during_execute once for every time stream#each_row yields' do
        stream_processor.execute
        expect(@call_counts).to eq(2)
      end
    end

    context 'when the callbacks collect the passed variables' do
      before do
        stream_processor.register(before_execute: lambda do
         @rows = []
         @row_counts = []
        end
        )
        stream_processor.register(during_execute: lambda do |row, row_count|
         @rows << row
         @row_counts << row_count
        end
        )
        stream_processor.register(after_execute: ->(row_count) { @after_row_count = row_count } )
      end

      it 'passes the row to the during_execute callback every time' do
        stream_processor.execute
        expect(@rows.first).to be (row)
        expect(@rows.length).to be(2)
      end

      it 'passes the row count to the during_execute callback every time' do
        stream_processor.execute
        expect(@row_counts.first).to be (1)
        expect(@row_counts.length).to be(2)
      end

      it "passes the final row count to the 'after_execute' callbacks" do
        stream_processor.execute
        expect(@after_row_count).to eq(2)
      end

      it 'returns the final row count' do
        expect(stream_processor.execute).to eq(2)
      end
    end
  end
end
