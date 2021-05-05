+++
showonlyimage = false
draft = false
image = "img/home/c-drive-panpan/c-drive-panpan.jpg"
date = 2021-04-28T20:12:04+09:00
title = "WSLがCドライブを圧迫していたので移動した"
+++

<!--more-->

#### 経緯

最近，メインPC（ゲーミング彼女）のCドライブの容量がみるみる少なくなっていくのに頭を抱えていた．250GBのSSD上に作成されたパーティションであり，個人フォルダの類はすべて他のストレージ（2TBのHDD）に移している．

使っていたストレージが250GBともともと少なかったわけであるが，かといっていきなり新しい大容量ストレージに換装しOSごと再インストールなんてこともできなかったため，ドライブを圧迫している犯人を突き止め可能であれば移動するという処置を取ることにした．

ちなみに，使っているストレージはSamsungの970 EVO Plus 250GB．

<iframe style="width:120px;height:240px;" marginwidth="0" marginheight="0" scrolling="no" frameborder="0" src="//rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=reyu735-22&language=ja_JP&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=B07MZ5LB7L&linkId=913437ec8aa14bdbe7baca0dd49b7081"></iframe>


Adobe製品のキャッシュ等々を消した時点での残り容量は17.2GBだった．

![残り17.2GB](/img/home/c-drive-panpan/c-red.jpg)

人力での犯人捜しは不可能なので，[DiskInfo](https://www.vector.co.jp/soft/winnt/util/se475617.html)というアプリケーションを使ってCドライブのルートから辿っていくと，ある一つのファイルに辿り着いた．

{{< tweet 1387328569953554434 >}}

それは，WSL（Windows Subsystem for Linux）によって作成される仮想ハードディスクファイル`ext4.vhdx`であった．250GBのうちの54.2GBとはなんたることか．

![仮想ハードディスクファイル](/img/home/c-drive-panpan/vhdx.jpg)

というわけで，WSLのファイルを他のドライブに移せないか調べてみたところ，いくつかのサイトでその方法が紹介されていた．とくに有用だったのが[このサイト](https://www.aise.ics.saitama-u.ac.jp/~gotoh/HowToReplaceWSL.html)である．

以下，WSLの移行手順を示す．

#### 手法

WSLが実行中だとさすがに移行は不可能なので，停止し，確認する．
```
> wsl --shutdown

> wsl -l -v
  NAME      STATE           VERSION
* Ubuntu    Stopped         2
```

STATEがStoppedになっていれば大丈夫．ちなみに，VERSIONはWSL1上で動作しているのか，WSL2上で動作しているかが分かる．

続いて，WSLのデータを容量に余裕のある任意の場所にエクスポートする．これはいわばバックアップのようなもので，仮想ディスクファイルを移行しない場合でも実行できる．
```
> wsl --export Ubuntu T:\wsl\ubuntu\Ubuntu.tar
```

結果，`T:\wsl\ubuntu\`にバックアップファイル`Ubuntu.tar`が作成される（念のため，事前に`mkdir t:\wsl\ubuntu`を実行していた）．tarでちょっとだけ圧縮されているのか，このファイルは52.6GBであった．

![バックアップ](/img/home/c-drive-panpan/tar.jpg)

続いて，WSLのデータの登録解除および削除を行う．
```
> wsl --unregister Ubuntu

> wsl -l -v
Linux 用 Windows サブシステムには、ディストリビューションがインストールされていません。
ディストリビューションは Microsoft Store にアクセスしてインストールすることができます:
https://aka.ms/wslstore
```

これでUbuntuの登録が解除されたことがわかった．また，仮想ディスクファイルも同時に削除されていることが分かる．

|![解除前](/img/home/c-drive-panpan/folder.jpg)|![解除後](/img/home/c-drive-panpan/folder2.jpg)|
|---|---|
|解除前|解除後|

さて，ここからが本日の大一番である，WSLへの再インポートだ．とはいえこれも一つのコマンドで実行することができて便利だ．

```
> wsl --import Ubuntu T:\wsl\ubuntu T:\wsl\ubuntu\Ubuntu.tar

> wsl -l -v
  NAME      STATE           VERSION
* Ubuntu    Stopped         2
```

先ほどと同様に，これと同時に仮想ディスクファイルがTドライブに作成されている．

![Tドライブに移動後](/img/home/c-drive-panpan/t-drive.jpg)

ここまでくれば，基本的にほとんど元通りの操作ができるようになる．一方で，そのまま起動してもデフォルトでrootを使わなければならなくなり，`su offnaria`といったひと手間が必要になる．

そこで，`wsl.exe`に適切な引数を与えて起動するショートカットを作成し，これまでのようにoffnariaとしてログインできるようにする．

![ショートカットに引数を与える](/img/home/c-drive-panpan/shortcut.jpg)

リンク先として`%windir%\System32\wsl.exe -u offnaria -d Ubuntu`を入力する．`-u`オプションはユーザ名を，`-d`オプションはインスタンス名を指定する（`%windir%\System32`にパスが通っているならこの部分は不要かも）．

作業フォルダーはログイン直後のカレントディレクトリを指定する．WSLのディレクトリ群はWindows上では`\\wsl$`以下に存在しているため，そこから辿ったホームディレクトリを指定すればよい．僕の場合は`\\wsl$\Ubuntu\home\offnaria`であった．

#### 結果

これで，今までのように起動直後から一般ユーザで作業を行うことができる．

![作業完了](/img/home/c-drive-panpan/complete.jpg)

#### 問題点

使っていたファイル等はこれまで通り存在しており，今のところ破損も見られない．しかしながら，一部のアプリケーションが動作しないといったことが起こっていた．

例えば，このサイトを作成している[hugo](https://gohugo.io/)もその一つで，ターミナルに`hugo`と入力しても`not found`が返されてしまった．再インストールのために`brew install hugo`を試したが，今度は[Homebrew](https://docs.brew.sh/Homebrew-on-Linux)も見つからなかった．幸いにしてHomebrewの再インストールで上手く動くようになったが，他にもこのようなアプリケーションがあるのではないかと心配である．

また，VSCodeを直接WSLに繋いだ際にrootでログインされてしまうので，例のごとく`su offnaria`を実行せねばならない．