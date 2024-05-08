# SPDX-License-Identifier: MIT
# Copyright 2024 hirmiura (https://github.com/hirmiura)
#
SHELL := /bin/bash

# 各種ディレクトリ
D_SWHOME	:= SpaceWill
D_SRC		:= src
D_BIN		:= bin
D_PAK		:= pak
# Note: \\wsl$\Debian は駄目なのでドライブを割り当てる
D_PAK_WIN	:= $(shell readlink -f $(D_PAK) | sed -e 's|^|L:|; s|/|\\|g')
D_LOC		:= loc
D_LOC_WIN	:= $(shell readlink -f $(D_LOC) | sed -e 's|^|L:|; s|/|\\|g')
D_GAME_LOCS	:= $(D_PAK)/StarryGame/Content/Localization/Game

# 各種ファイル
F_SWPAK		:= $(D_SWHOME)/StarryGame/StarryGame/Content/Paks/StarryGame-Windows.pak
F_SWPAK_WIN	:= $(shell readlink -f $(F_SWPAK) | sed -e 's|^/mnt/\(\w\)/|\1:/|; s|/|\\|g')
L_LOCRES	:= $(foreach locale,en ja zh,$(D_GAME_LOCS)/$(locale)/Game.locres)

# コマンド
E_CMD		:= /mnt/c/Windows/System32/cmd.exe
E_URPAK		:= /mnt/c/EpicGames/UE_5.4/Engine/Binaries/Win64/UnrealPak.exe
E_URLOCRES	:= $(D_BIN)/UnrealLocres.exe
E_POTRANS	:= $(D_SRC)/potrans/potrans.py

# URL
URL_URLOCRES	:= https://github.com/akintos/UnrealLocres/releases/download/1.1.1/UnrealLocres.exe


#==============================================================================
# カラーコード
# ヘルプ表示
#==============================================================================
include ColorCode.mk
include Help.mk


#==============================================================================
# 各種確認
#==============================================================================
.PHONY: check
check: ## 事前にチェック項目を確認します
check: check_link check_urlocres


#==============================================================================
# SpaceWill本体へのリンク/ディレクトリを確認
#==============================================================================
.PHONY: check_link
check_link: ## SpaceWill本体へのリンク/ディレクトリを確認します
check_link:
	@echo -e '$(CC_BrBlue)========== $@ ==========$(CC_Reset)'
	@echo '"$(D_SWHOME)" をチェックしています'
	@if [[ -L $(D_SWHOME) && `readlink $(D_SWHOME) ` ]] ; then \
		echo -e '    $(CC_BrGreen)SUCCESS$(CC_Reset): リンクです' ; \
	elif [[ -d $(D_SWHOME) ]] ; then \
		echo -e '    $(CC_BrGreen)SUCCESS$(CC_Reset): ディレクトリです' ; \
	else \
		echo -e '    \a$(CC_BrRed)ERROR: "$(D_SWHOME)" に "SpaceWill" へのリンクを張って下さい$(CC_Reset)' ; \
		echo -e '    $(CC_BrRed)例: ln -s "/mnt/c/SteamLibrary/steamapps/common/The will of space" $(D_SWHOME)$(CC_Reset)' ; \
		exit 1 ; \
	fi


#==============================================================================
# UnrealLocres.exeを確認
#==============================================================================
.PHONY: check_urlocres
check_urlocres: ## UnrealLocres.exeを確認します
check_urlocres: $(E_URLOCRES)

$(E_URLOCRES):
	@echo -e '$(CC_BrBlue)========== $@ ==========$(CC_Reset)'
	@echo '"$(E_URLOCRES)" をチェックしています'

	@if [[ -L $(E_URLOCRES) && `readlink $(E_URLOCRES) ` ]] ; then \
		echo -e '    $(CC_BrGreen)SUCCESS$(CC_Reset): リンクです' ; \
	elif [[ -f $(E_URLOCRES) ]] ; then \
		echo -e '    $(CC_BrGreen)SUCCESS$(CC_Reset): ファイルです' ; \
	else \
		echo -e '    \a$(CC_BrRed)ERROR: "$(E_URLOCRES)" が見つかりません$(CC_Reset)' ; \
		echo -e '    \a$(CC_BrRed)ダウンロードします$(CC_Reset)' ; \
		wget -nc -P $(D_BIN) $(URL_URLOCRES) ; \
		exit 1 ; \
	fi
	@chmod 755 $(E_URLOCRES)


#==============================================================================
# pakを展開
#==============================================================================
.PHONY: unpak
unpak: ## pakを展開します
unpak: $(E_URPAK) check_link
	@echo -e '$(CC_BrBlue)========== $@ ==========$(CC_Reset)'
	mkdir -p $(D_PAK)
	"$(E_URPAK)" "$(F_SWPAK_WIN)" -Extract "$(D_PAK_WIN)" -Filter=StarryGame/Content/Localization/Game/*


#==============================================================================
# locresを展開
#==============================================================================
.PHONY: unpack_locres
unpack_locres: ## locresを展開します
unpack_locres: $(L_LOCRES) $(E_URLOCRES)
	@echo -e '$(CC_BrBlue)========== $@ ==========$(CC_Reset)'
	mkdir -p $(D_LOC)
	$(foreach locale,en ja zh,$(E_URLOCRES) export -f pot $(D_GAME_LOCS)/$(locale)/Game.locres -o $(D_LOC)/$(locale).pot && ) true

$(L_LOCRES):
	$(MAKE) unpak


#==============================================================================
# potrans.pyを実行
#==============================================================================
.PHONY: potrans
potrans: ## potrans.pyを実行します
potrans: $(D_LOC)/ja.po
	@echo -e '$(CC_BrBlue)========== $@ ==========$(CC_Reset)'
	$(E_POTRANS) -i $(D_LOC)/ja.po

$(D_LOC)/ja.po: $(D_LOC)/en.pot
	@echo -e '$(CC_BrBlue)========== $@ ==========$(CC_Reset)'
	@if ! [[ -f "$@" ]] ; then \
		msginit --no-translator -l ja_JP.utf8 -i $< -o $@ ; \
	fi


#==============================================================================
# locresをリパック
#==============================================================================
.PHONY: pack_locres
pack_locres: ## locresをリパックします
pack_locres: $(D_LOC)/Game.locres

$(D_LOC)/Game.locres: $(D_LOC)/ja.po $(D_GAME_LOCS)/en/Game.locres $(E_URLOCRES)
	@echo -e '$(CC_BrBlue)========== $@ ==========$(CC_Reset)'
	$(E_URLOCRES) import -f po $(D_GAME_LOCS)/en/Game.locres $(D_LOC)/ja.po -o $(D_LOC)/Game.locres


#==============================================================================
# pakを作成
#==============================================================================
.PHONY: pack_pak
pack_pak: ## pakを作成します
pack_pak: $(D_LOC)/StarryGame-Windows_update-ja.pak $(E_URPAK)

$(D_LOC)/StarryGame-Windows_update-ja.pak: $(D_LOC)/Game.locres $(D_LOC)/packing.txt
	@echo -e '$(CC_BrBlue)========== $@ ==========$(CC_Reset)'
	$(E_URPAK) "$(D_LOC_WIN)\StarryGame-Windows_update-ja.pak" -Create="$(D_LOC_WIN)\packing.txt" -compressed -compressionformat=Oodle

$(D_LOC)/packing.txt:
	@echo -e '$(CC_BrBlue)========== $@ ==========$(CC_Reset)'
	echo '"$(D_LOC_WIN)\Game.locres" "../../../StarryGame/Content/Localization/Game/ja/"' > $@


#==============================================================================
# ビルド
#==============================================================================
.PHONY: build
build: ## ビルドする
build: clean-locres clean-package pack_pak


#==============================================================================
# 全ての作業を一括で実施する
#==============================================================================
.PHONY: all
all: ## 全ての作業を一括で実施する
all: unpack_locres potrans build


#==============================================================================
# クリーンアップ
#==============================================================================
.PHONY: clean clean-all clean-pak clean-pot clean-locres clean-package clean-urlocres
clean: ## クリーンアップします
clean: clean-locres clean-package

clean-all: ## 生成した全てのファイルを削除します
clean-all: clean clean-locres clean-pak clean-pot clean-urlocres

clean-pak: ## pak周りを削除します
clean-pak:
	@echo -e '$(CC_BrMagenta)========== $@ ==========$(CC_Reset)'
	rm -fr $(D_PAK)

clean-pot: ## potファイルを削除します
clean-pot:
	@echo -e '$(CC_BrMagenta)========== $@ ==========$(CC_Reset)'
	rm -f $(D_LOC)/*.pot

clean-locres: ## locres周りを削除します
clean-locres:
	@echo -e '$(CC_BrMagenta)========== $@ ==========$(CC_Reset)'
	rm -f $(D_LOC)/Game.locres

clean-package: ## パッケージ周りを削除します
clean-package:
	@echo -e '$(CC_BrMagenta)========== $@ ==========$(CC_Reset)'
	rm -f $(D_LOC)/StarryGame-Windows_update-ja.pak $(D_LOC)/packing.txt

clean-urlocres: ## $(E_URLOCRES)を削除します
clean-urlocres:
	@echo -e '$(CC_BrMagenta)========== $@ ==========$(CC_Reset)'
	rm -f $(E_URLOCRES)
