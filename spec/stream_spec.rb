require 'spec_helper'

describe PgStream::Stream do
  let(:db_conn) { instance_double('PG::Connection', send_query: self, set_single_row_mode: self) }
  let(:row) { ['test@example.com', '1234567'] }
  let(:fields) { ['email', 'id']  }
  let(:values) { [row] }
  let(:res) { instance_double('PG::Result', check: nil, fields: fields, values: values) }
  let(:empty_res) { instance_double('PG::Result', check: nil, fields: fields, values: [nil]) }
  let(:body) { 'SELECT email, id FROM warehouse.email_user_targetings LIMIT 1;' }
  let(:pg_stream) { PgStream::Stream.new(db_conn, body) }

  before do
    allow(db_conn).to receive(:get_result).and_return(res, res, nil)
    allow(res).to receive(:each_row).and_yield(row)
  end

  describe '#headers' do
    it 'returns the headers of the columns of the query result' do
      expect(pg_stream.headers).to eq(fields)
    end
  end

  describe '#each_row' do
    let(:result_collector) { [] }

    it 'yields a row for each result until PG::Connection#get_result returns nil' do
      pg_stream.each_row { |query_row| result_collector << query_row }
      expect(result_collector.length).to eq(2)
      expect(result_collector.last).to eq(row)
    end

    context 'when the query returns no results' do
      before { allow(db_conn).to receive(:get_result).and_return(empty_res) }

      it 'yields no rows' do
        pg_stream.each_row { |query_row| result_collector << query_row }
        expect(result_collector.length).to eq(0)
      end
    end
  end
end
