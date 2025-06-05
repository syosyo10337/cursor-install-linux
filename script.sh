#!/bin/bash

# Cursor AppImage インストールスクリプト
# 使用方法: install-cursor [検索ディレクトリ]

set -e  # エラーが発生したら終了

# 色付きメッセージ用の関数
print_success() {
    echo -e "\e[32m✓ $1\e[0m"
}

print_error() {
    echo -e "\e[31m✗ $1\e[0m"
}

print_info() {
    echo -e "\e[34mℹ $1\e[0m"
}

print_warning() {
    echo -e "\e[33m⚠ $1\e[0m"
}

# 検索ディレクトリ（引数で指定可能）
SEARCH_DIR="${1:-$HOME/Downloads}"
TARGET_DIR="/opt/cursor"
TARGET_FILE="$TARGET_DIR/cursor.AppImage"

# ヘルプ表示
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "使用方法: $(basename "$0") [検索ディレクトリ]"
    echo "デフォルトの検索ディレクトリ: ~/Downloads"
    exit 0
fi

print_info "Cursor AppImage インストーラーを開始します..."
print_info "検索ディレクトリ: $SEARCH_DIR"

# 検索ディレクトリの存在確認
if [ ! -d "$SEARCH_DIR" ]; then
    print_error "ディレクトリが見つかりません: $SEARCH_DIR"
    exit 1
fi

# Cursor*.AppImageファイルを検索
print_info "Cursor AppImageファイルを検索中..."
cursor_files=($(find "$SEARCH_DIR" -maxdepth 1 -name "Cursor-*.AppImage" -type f 2>/dev/null))

# ファイルが見つからない場合
if [ ${#cursor_files[@]} -eq 0 ]; then
    print_error "Cursor AppImageファイルが見つかりません。"
    print_info "以下のような名前のファイルを探しています: Cursor-*.AppImage"
    print_info "場所: $SEARCH_DIR"
    exit 1
fi

# 見つかったファイルを表示
print_success "${#cursor_files[@]}個のCursor AppImageファイルが見つかりました:"
echo

for i in "${!cursor_files[@]}"; do
    filename=$(basename "${cursor_files[$i]}")
    filesize=$(du -h "${cursor_files[$i]}" | cut -f1)
    filedate=$(stat -c "%y" "${cursor_files[$i]}" | cut -d' ' -f1,2 | cut -d'.' -f1)
    echo "  $((i+1)). $filename"
    echo "     サイズ: $filesize, 更新日時: $filedate"
done

echo

# 複数ファイルがある場合は選択を求める
if [ ${#cursor_files[@]} -gt 1 ]; then
    while true; do
        echo -n "インストールするファイルの番号を選択してください (1-${#cursor_files[@]}): "
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#cursor_files[@]} ]; then
            selected_file="${cursor_files[$((choice-1))]}"
            break
        else
            print_warning "無効な選択です。1から${#cursor_files[@]}の間の数字を入力してください。"
        fi
    done
else
    selected_file="${cursor_files[0]}"
fi

selected_filename=$(basename "$selected_file")
print_info "選択されたファイル: $selected_filename"

# 権限確認
if [ ! -w "$(dirname "$TARGET_DIR")" ]; then
    print_warning "管理者権限が必要です。sudoを使用します。"
    SUDO="sudo"
else
    SUDO=""
fi

# /opt/cursorディレクトリを作成
print_info "/opt/cursorディレクトリを作成中..."
$SUDO mkdir -p "$TARGET_DIR"

# ファイルをコピーしてリネーム
print_info "ファイルをインストール中..."
$SUDO cp "$selected_file" "$TARGET_FILE"

# 実行権限を付与
$SUDO chmod +x "$TARGET_FILE"

print_success "インストールが完了しました!"
print_info "インストール先: $TARGET_FILE"

# Desktop エントリの作成
desktop_file="/usr/share/applications/cursor.desktop"
if [ ! -f "$desktop_file" ]; then
    print_info "Desktop エントリを作成しますか? [Y/n]: "
    read -r create_desktop
    if [[ ! "$create_desktop" =~ ^[Nn]$ ]]; then
        $SUDO tee "$desktop_file" > /dev/null << EOF
[Desktop Entry]
Name=Cursor
Exec=/opt/cursor/cursor.AppImage %F
Terminal=false
Type=Application
Icon=cursor
StartupWMClass=Cursor
Comment=AI-powered code editor
Categories=Development;IDE;
MimeType=text/plain;
EOF
        print_success "Desktop エントリを作成しました。"
    fi
else
    print_success "Desktop エントリが既に存在します: $desktop_file"
fi

# 元ファイルの削除確認
echo
echo -n "元のファイル ($selected_filename) を削除しますか? [y/N]: "
read -r delete_choice

if [[ "$delete_choice" =~ ^[Yy]$ ]]; then
    rm "$selected_file"
    print_success "元のファイルを削除しました。"
else
    print_info "元のファイルは保持されます。"
fi

print_success "すべての処理が完了しました!"
print_info "アプリケーションメニューからCursorを起動できます。"