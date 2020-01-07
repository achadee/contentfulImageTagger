require_relative '../handler.rb'
require 'test/unit'

class TestHandler < Test::Unit::TestCase
    def test_active_endpoint()
        response = api(event: {}, context: {})
        assert response[:statusCode] >= 200
    end
end
