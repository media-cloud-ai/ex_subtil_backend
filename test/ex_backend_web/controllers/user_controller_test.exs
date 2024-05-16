defmodule ExBackendWeb.UserControllerTest do
  use ExBackendWeb.ConnCase

  import ExBackendWeb.AuthCase
  alias ExBackend.Accounts
  alias ExBackendWeb.Auth.Token

  @create_attrs %{
    first_name: "Bill",
    last_name: "Smith",
    email: "bill@example.com",
    password: "hard2guess"
  }
  @update_attrs %{email: "william@example.com"}
  @invalid_attrs %{email: nil}

  setup %{conn: conn} = config do
    if email = config[:login] do
      user = add_user("Bill", "Smith", email, config[:roles] || ["administrator"])
      other = add_user("Tony", "Stank", "tony@example.com")
      conn = conn |> add_token_conn(user)
      {:ok, %{conn: conn, user: user, other: other}}
    else
      {:ok, %{conn: conn}}
    end
  end

  @tag login: "reg@example.com"
  test "lists all entries on index", %{conn: conn} do
    conn = get(conn, user_path(conn, :index))
    assert json_response(conn, 200)
  end

  test "renders /users error for unauthorized user", %{conn: conn} do
    conn = get(conn, user_path(conn, :index))
    assert json_response(conn, 401)
  end

  @tag login: "reg@example.com"
  test "show chosen user's page", %{conn: conn, user: user} do
    conn = get(conn, user_path(conn, :show, user))

    assert %{
             "id" => user_id,
             "email" => "reg@example.com",
             "confirmed_at" => nil,
             "roles" => ["administrator"],
             "inserted_at" => _inserted_at
           } = json_response(conn, 200)["data"]

    assert user_id == user.id
  end

  @tag login: "reg@example.com"
  test "creates user when data is valid", %{conn: conn} do
    conn = post(conn, user_path(conn, :create), user: @create_attrs)
    assert json_response(conn, 201)["data"]["id"]
    assert Accounts.get_by(%{"email" => "bill@example.com"})
  end

  @tag login: "reg@example.com"
  test "does not create user and renders errors when data is invalid", %{conn: conn} do
    conn = post(conn, user_path(conn, :create), user: @invalid_attrs)
    assert json_response(conn, 422)["errors"] != %{}
  end

  @tag login: "reg@example.com"
  test "updates chosen user when data is valid", %{conn: conn, user: user} do
    conn = put(conn, user_path(conn, :update, user), user: @update_attrs)
    assert json_response(conn, 200)["data"]["id"] == user.id
    updated_user = Accounts.get(user.id)
    assert updated_user.email == "william@example.com"
  end

  @tag login: "reg@example.com"
  test "does not update chosen user and renders errors when data is invalid", %{
    conn: conn,
    user: user
  } do
    conn = put(conn, user_path(conn, :update, user), user: @invalid_attrs)
    assert json_response(conn, 422)["errors"] != %{}
  end

  @tag login: "reg@example.com", roles: ["administrator"]
  test "generate credentials for chosen user when data is valid", %{conn: conn, user: user} do
    conn = post(conn, user_path(conn, :generate_credentials, id: user.id))
    assert json_response(conn, 200)["data"]["id"] == user.id
    updated_user = Accounts.get(user.id)
    <<head::binary-size(4)>> <> _rest = updated_user.access_key_id
    assert head == "MCAI"
    assert String.length(updated_user.access_key_id) == 20
    assert String.length(updated_user.secret_access_key) == 40
  end

  @tag login: "reg@example.com", roles: ["technician", "editor"]
  test "does not generate credentials for unauthorized user", %{
    conn: conn,
    user: user
  } do
    conn = post(conn, user_path(conn, :generate_credentials, id: user.id))
    assert json_response(conn, 403)["errors"] != %{}
  end

  @tag login: "reg@example.com"
  test "unable to delete myself", %{conn: conn, user: user} do
    conn = delete(conn, user_path(conn, :delete, user))
    assert response(conn, 403)
  end

  @tag login: "reg@example.com"
  test "delete an another user", %{conn: conn, other: other} do
    conn = delete(conn, user_path(conn, :delete, other))
    assert response(conn, 204)
  end

  @tag login: "reg@example.com", roles: ["editor"]
  test "check editor role on delete", %{conn: conn, other: other} do
    conn = delete(conn, user_path(conn, :delete, other))
    assert response(conn, 403)
  end

  @tag login: "reg@example.com", roles: ["technician"]
  test "check technician role on delete", %{conn: conn, other: other} do
    conn = delete(conn, user_path(conn, :delete, other))
    assert response(conn, 403)
  end

  @tag login: "reg@example.com", roles: ["technician", "editor"]
  test "check multi roles on delete", %{conn: conn, other: other} do
    conn = delete(conn, user_path(conn, :delete, other))
    assert response(conn, 403)
  end

  @tag login: "reg@example.com", roles: ["administrator", "technician", "editor"]
  test "check multi roles with administrator on delete", %{conn: conn, other: other} do
    conn = delete(conn, user_path(conn, :delete, other))
    assert response(conn, 204)
  end

  @tag login: "reg@example.com", roles: ["technician"]
  test "check validation link fails when not an administrator", %{
    conn: conn,
    user: user
  } do
    conn = post(conn, user_path(conn, :generate_validation_link, id: user.id))
    assert json_response(conn, 403)["errors"] != %{}
  end

  @tag login: "reg@example.com", roles: ["administrator"]
  test "check validation link fails if user id does not exist", %{
    conn: conn,
    user: _user
  } do
    catch_error(post(conn, user_path(conn, :generate_validation_link, id: "2000")))
  end

  @tag login: "reg@example.com", roles: ["administrator"]
  test "check validation link success", %{
    conn: conn,
    user: user
  } do
    conn = post(conn, user_path(conn, :generate_validation_link, id: user.id))
    request = json_response(conn, 200)["validation_link"]

    token =
      request
      |> String.split("=")
      |> Enum.at(1)

    test =
      case Token.verify_token(conn, token) do
        {:ok, _access_token} ->
          user.email

        _ ->
          "Error"
      end

    assert test == "reg@example.com"
  end
end
