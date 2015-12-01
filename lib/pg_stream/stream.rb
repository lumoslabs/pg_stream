module PgStream
  class Stream
    def initialize(db_conn, body)
      @db_conn = db_conn
      @db_conn.send_query(body)
      @db_conn.set_single_row_mode
    end

    def headers
      @headers ||= get_headers
    end

    def each_row(&block)
      headers # ensure that headers has been called so we have the first row
      return unless @first_row # dont yield any rows if the query returns no results
      yield(@first_row)

      loop do
        res = @db_conn.get_result || break
        res.check
        res.each_row do |row|
          yield(row)
        end
      end
    end

    private

    def get_headers
      first_row_result = @db_conn.get_result
      first_row_result.check

      # values is method on the result object, which can have many rows,
      # but which will only return one row in single_row_mode
      @first_row = first_row_result.values[0]

      first_row_result.fields
    end
  end
end
