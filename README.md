# Simple YOLO dataset creator with Flutter

Flutterで開発した、非常に簡素な機能のYOLOデータセット作成ソフトです。  
開発者はプログラミング初心者のため、プロジェクトにはバグ、例外処理の不備、設計など、問題点は枚挙にいとまがありません。  
ご意見・ご助言等いただけますと、非常に幸いです。  

## Instructions for Use

https://github.com/omomo17/Simple_YOLO_dataset_creator/assets/65716029/e91c6b16-bdb5-43a2-9d01-aa2a79b5b3a1

1. 【フォルダ】アイコンをクリックし、ラベリングしたい画像が保存されているフォルダを開きます。
2. 選択したフォルダにdataset.yamlが存在しない場合、新たに作成します。存在する場合は読み込みます。
3. 【テキストフィールド】にクラス名を書き、Enterまたは【+】アイコンをクリックすると新しいクラスが追加されます。
4. 画像上でドラッグ＆ドロップすることで四角形を描画します。緑色の状態では未保存状態であり、ミスがあればそのまま再描画できます。
5. クラスを選択したうえで【保存】アイコンをクリックし、描画した四角形が青色になればラベルの保存完了です。
6. 【>】アイコンで次の画像を表示します。

# Roadmap

## Bug fix
+ ショートカットキーの常時有効化(テキストフィールドに一度フォーカスしないと有効化しない)
+ ctrlを押しただけでfolderが開く問題(ctrl+Fで開く設定にしているつもり)

## Features to be Added
+ 無効な操作をした場合のポップアップ表示
+ bboxやlabelの削除・修正機能
+ クラスごとに分かれたカラーリング
+ 既にラベルが付与されている画像は表示しない機能

## Refactoring
+ ファイル・クラス・責任の分割
+ コメントの付与
+ 命名規則見直し
