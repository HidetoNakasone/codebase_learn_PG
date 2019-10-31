
require 'sinatra'
require 'sinatra/reloader'
# PostgreSQLを利用できるGemをrequireする
require 'pg'

enable :sessions

# PostgreSQLに接続するための、仲介役(client)を作成する
# このclientに用意されているメソッドを経由して、PostgreSQLにSQL文を送信する
client = PG::connect(
  :host => "localhost",
  :user => '', :password => '',
  :dbname => "myapp")


# GETのエンドポイント /mypage を用意
# http://localhost:4567/mypage でアクセスできる
get '/mypage' do
  # 1. viewで変数を読み込めるように、@をつけた変数に代入する
  # 2. 今回は、/sign_in(一つ上のプログラム)で設定したsessionからnameを取り出して@usernameに入れる
  @username = session[:name]

  # SELECT文で、指定したデータを取得できる
  # 今回はnameに$1を「後から」挿入する
  # 今回のSQLは、sessionで保存したnameと同じユーザーを取得するもの
  sql = "select * from users where name = $1"
  # ↑のSQL文の$1に@usernameが挿入される
  # 実行結果はusersテーブルから取得したデータなので、user変数に入れる
  user = client.exec_params(sql, [@username])

  # 取得したユーザーが存在する = userは配列なので、配列の長さが1なら、というif文
  if user.count == 1
    # user.countが1なら、ユーザーが存在するということなので
    # 取得したuserを@userに入れ直してviewで表示できるようにする
    @user = user[0]
  end

  # views/mypage.erb を表示する
  erb :mypage
end

# GETのエンドポイント /sign_up を用意
# http://localhost:4567/sign_up にアクセスできる
get '/sign_up' do
  # views/sign_up.erbを読み込む
  erb :sign_up
end

# POSTのエンドポイント /sign_up を用意
# http://localhost:4567/sign_up にPOSTでアクセスできる
post '/sign_up' do

  # 1. viewで変数を読み込めるように、@をつけた変数に代入する
  # 2. <input type="email" name="email" id="email" /> の name=「"email"」 がparams[:email] として読み出せる
  # 3. なので、 @email = params[:email] と書くことで、POSTされたemail(例えば「kabi@mail.com」)が@email変数の中に入ってくれる
  @name = params[:name]
  @email = params[:email]
  @password = params[:password]

  # デバッグ用のSQL文、重複したメールアドレスが登録できないので、事前にデータを削除する
  # sql = "DELETE FROM users WHERE name=$1;"
  # client.exec_params(sql, [@name])

  # INSERT文で、新しくデータを追加できる、nameに$1、emailに$2、passwordに$3で指定した変数を「後から」挿入する
  sql = "INSERT INTO users (name, email, password) VALUES ($1, $2, $3);"
  # clientは、上の方で定義したもの。exec_paramsは
  # (SQL文となる文字列, [変数1, 変数2, 変数3, ...以下好きなだけ]) というような記述ができる
  # SQL文の$1や$2に対して、変数1、変数2が挿入されるようになる
  # 今回の場合↓ $1に@name、$2に@email、$3に@passwordが入る
  client.exec_params(sql, [@name, @email, @password])
  # 後から、というのは、↑この時

  # http://localhost:4567/sign_up にリダイレクト(ページ遷移)するための記述
  redirect to('/sign_in')
end

# GETエンドポイント /sign_in を用意
# http://localhost:4567/sign_in にアクセスできる
get '/sign_in' do
  # views/sign_in.erbを読み込む
  erb :sign_in
end

# POSTエンドポイント /sign_in を用意
# http://localhost:4567/sign_in にPOSTでアクセスできる
post '/sign_in' do
  # 1. viewで変数を読み込めるように、@をつけた変数に代入する
  # 2. <input type="email" name="email" id="email" /> の name=「"email"」 がparams[:email] として読み出せる
  # 3. なので、 @email = params[:email] と書くことで、POSTされたemail(例えば「kabi@mail.com」)が@email変数の中に入ってくれる
  @email = params[:email]
  @password = params[:password]

  # SELECT文で、指定したデータを取得できる
  # emailに$1、passwordに$2で指定した変数を「後から」挿入する
  # 今回のSQLは、入力されたemailとpasswordが一致するユーザーを取得するもの
  sql = "select * from users where email = $1 and password = $2"
  # ↑のSQL文の$1に@email、$2に@passwordが挿入される
  # 実行結果はusersテーブルから取得したデータなので、user変数に入れる
  user = client.exec_params(sql, [@email, @password])
  # 後から、というのは↑この時

  # 取得したユーザーが存在する = userは配列なので、配列の長さが1なら、というif文
  if user.count == 1
    # user.countが1なら、ユーザーが存在するということなので
    # session[:name] に user配列の最初の要素、のnameを取得する
    session[:name] = user[0]['name']
    # binding.pry # を実行すると、user[0]の中身がどうなっているか確認ができる

    # セッションにデータを入れたら、 http://localhost:4567/mypage にリダイレクトする
    redirect to('/mypage')
    # このpostのプログラムは、ここで終了する
    return
    # returnをここに書いたことで、↓下のプログラムは実行されない
  end

  # もしuser.countが1じゃなければ、http://localhost:4567/sign_in にリダイレクトする
  redirect to('/sign_in')
end
