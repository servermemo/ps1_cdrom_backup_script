#!/bin/bash

# 使用法: ./ps1_backup.sh デバイス名 "ゲームタイトル"

# $1 = デバイス名 
# $2 = ゲーム名

DEVICE="$1"
GAME_NAME="$2"
DRIVER="generic-mmc:0x20000"

# 引数が2つ揃っているかチェック
if [ "$#" -ne 2 ]; then
    echo "エラー: 引数が正しくありません。"
    echo "使い方: $0 デバイス名 ゲーム名 を指定してください"
    echo "   例: $0 /dev/cdrom \"gamename\""
    exit 1
fi

# cdrdaoとtoc2cueがインストールされているかチェック
if ! command -v cdrdao &> /dev/null || ! command -v toc2cue &> /dev/null; then
    echo "エラー: cdrdao または toc2cue がインストールされていません。"
    exit 1
fi

echo "####################################"
echo "PS1 CD-ROM Backup Start "
echo "デバイス ${DEVICE} から "
echo "${GAME_NAME} をバックアップします...  "
echo "####################################"

# データバックアップ
# 成功したらトレイを開く

if cdrdao read-cd \
    --device "${DEVICE}" \
    --driver "${DRIVER}" \
    --speed 4 \
    --paranoia-mode 3 \
    -v 2 \
    --read-raw \
    --datafile "${GAME_NAME}.bin" "${GAME_NAME}.toc"; then

    # バックアップ成功
    echo "####################################"
    echo " 吸い出し成功。トレイを開きます。"
    echo "####################################"
    eject "${DEVICE}"
else
    # バックアップ失敗
    echo "####################################"
    echo " エラー: バックアップに失敗しました。"
    echo "####################################"
    exit 1
fi

# tocをcueに変換

if [ -f "${GAME_NAME}.toc" ]; then
    echo "###################################"
    echo " cueファイルへの変換を行います..."
    echo "###################################"

    toc2cue "${GAME_NAME}.toc" "${GAME_NAME}.cue"

    echo "###################################"
    echo " 完了しました。                  "
    echo "###################################"

    #PS1用にMODE設定を自動修正する（MODE1になっていたらMODE2に置換）
    if grep -q "MODE1/2048" "${GAME_NAME}.cue"; then
        echo "修正: CUEシートの MODE1 を MODE2 に書き換えます..."
        sed -i 's/MODE1\/2048/MODE2\/2352/g' "${GAME_NAME}.cue"
    fi
fi
