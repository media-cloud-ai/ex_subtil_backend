defmodule ExBackendWeb.SessionControllerTest do
  use ExBackendWeb.ConnCase

  import ExBackendWeb.AuthCase

  @create_attrs %{
    first_name: "Robin",
    last_name: "Hood",
    email: "robin@example.com",
    password: "reallyHard2gue$$"
  }
  @invalid_attrs %{
    first_name: "Robin",
    last_name: "Hood",
    email: "robin@example.com",
    password: "cannotGue$$it"
  }
  @unconfirmed_attrs %{
    first_name: "Lancelot",
    last_name: "Roundtable",
    email: "lancelot@example.com",
    password: "reallyHard2gue$$"
  }

  setup %{conn: conn} do
    add_user("Lancelot", "Roundtable", "lancelot@example.com")
    user = add_user_confirmed("Robin", "Hood", "robin@example.com")
    {:ok, %{conn: conn, user: user}}
  end

  test "login succeeds", %{conn: conn} do
    conn = post(conn, session_path(conn, :create), session: @create_attrs)
    assert json_response(conn, 200)["access_token"]
  end

  test "login fails for user that is not yet confirmed", %{conn: conn} do
    conn = post(conn, session_path(conn, :create), session: @unconfirmed_attrs)
    assert json_response(conn, 401)["error"]["message"] =~ "Invalid email or password"
  end

  test "login fails for user that is already logged in", %{conn: conn, user: user} do
    conn = conn |> add_token_conn(user)
    conn = post(conn, session_path(conn, :create), session: @create_attrs)
    assert json_response(conn, 401)["errors"]["detail"] =~ "You are already logged in"
  end

  test "login fails for invalid password", %{conn: conn} do
    conn = post(conn, session_path(conn, :create), session: @invalid_attrs)
    assert json_response(conn, 401)["error"]["message"] =~ "Invalid email or password"
  end
end
