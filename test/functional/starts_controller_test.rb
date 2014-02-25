require 'test_helper'

class StartsControllerTest < ActionController::TestCase
  setup do
    @start = starts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:starts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create start" do
    assert_difference('Start.count') do
      post :create, :start => {  }
    end

    assert_redirected_to start_path(assigns(:start))
  end

  test "should show start" do
    get :show, :id => @start
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @start
    assert_response :success
  end

  test "should update start" do
    put :update, :id => @start, :start => {  }
    assert_redirected_to start_path(assigns(:start))
  end

  test "should destroy start" do
    assert_difference('Start.count', -1) do
      delete :destroy, :id => @start
    end

    assert_redirected_to starts_path
  end
end
