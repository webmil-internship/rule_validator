#Dir["#{File.dirname(__FILE__)} /../lib/**/*.rb"].each { |file| require file }
require_relative "../lib/config_load.rb"
require_relative "../lib/jwt_validator/algorithms/hmac.rb"
require_relative "../lib/jwt_validator/algorithms/rs256.rb"
require_relative "../lib/jwt_validator/base_service.rb"
require_relative "../lib/jwt_validator/exceptions.rb"
require_relative "../lib/jwt_validator/validator.rb"
require_relative "../lib/my_app.rb"
require_relative "../lib/rule_validator_middleware/parsed_request.rb"
require_relative "../lib/rule_validator_middleware/db_factory.rb"
require_relative "../lib/rule_validator_middleware/parsing_route/node.rb"
require_relative "../lib/rule_validator_middleware/parsing_route/parsing_rule.rb"
require_relative "../lib/rule_validator_middleware/parsing_route/tree.rb"
require_relative "../lib/rule_validator_middleware/rule_validator.rb"
require_relative "../lib/rule_validator_middleware/storages/base_storage.rb"
require_relative "../lib/rule_validator_middleware/storages/mongo.rb"
require_relative "../lib/rule_validator_middleware/storages/redis.rb"
require_relative "../lib/rule_validator_middleware/storages/yaml.rb"
require_relative "../lib/rule_validator_middleware/validator.rb"
require_relative "../lib/whitelist_validator/checker.rb"
require_relative "../lib/whitelist_validator/validator.rb"

require 'jwt'
require 'test/unit'
require 'rack/test'

class MainTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    RuleValidator.new(
      JwtValidator::Validator.new(
        WhiteListValidator::Validator.new(
          MyApp.new)))
  end

  def setup
    @payload = { "user": 1 }
    @algo    = 'HS256'
    @secret  = 'secret'

    @valid_token   = JWT.encode @payload, @secret, @algo
    @invalid_token = JWT.encode @payload, 'something else', @algo
  end

  def test_status_200_with_domen_from_white_list_valid_token
    header 'Authorization', "Bearer #{@valid_token}"
    get 'http://dots.com/signin'

    assert_equal(last_response.status, 200)
  end

  def test_status_200_with_domen_from_white_list_invalid_token
    header 'Authorization', "Bearer #{@invalid_token}"
    get 'http://dots.com/signin'

    assert_equal(last_response.status, 200)
  end

  def test_status_401_with_domen_not_from_white_list_invalid_token_v2
    header 'Authorization', "Bearer #{@valid_token}"

    assert_raises(Exceptions::RouteMissing) {get 'http://dots.com/tests'}
  end

  def test_status_401_with_domen_not_from_white_list_invalid_token
    header 'Authorization', "Bearer #{@invalid_token}"
    get 'http://dots.com/tests'

    assert_equal(last_response.status, 401)
  end

  def test_status_200_with_domen_from_tree_routes_valid_token
    header 'Authorization', "Bearer #{@valid_token}"
    get 'http://dots.com/account/workspaces/12/members/admin'

    assert_equal(last_response.status, 200)
  end
end
