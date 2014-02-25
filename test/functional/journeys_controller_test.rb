require 'test_helper'

class JourneysControllerTest < ActionController::TestCase
  setup do
    @journey = journeys(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:journeys)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create journey" do
    assert_difference('Journey.count') do
      post :create, :journey => {  }
    end

    assert_redirected_to journey_path(assigns(:journey))
  end

  test "should show journey" do
    get :show, :id => @journey
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @journey
    assert_response :success
  end

  test "should update journey" do
    put :update, :id => @journey, :journey => {  }
    assert_redirected_to journey_path(assigns(:journey))
  end

  test "should destroy journey" do
    assert_difference('Journey.count', -1) do
      delete :destroy, :id => @journey
    end

    assert_redirected_to journeys_path
  end
end
