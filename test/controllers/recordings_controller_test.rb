require "test_helper"

class RecordingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get recordings_index_url
    assert_response :success
  end

  test "should get show" do
    get recordings_show_url
    assert_response :success
  end
end
