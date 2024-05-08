#!/usr/bin/env -S python3
# SPDX-License-Identifier: MIT
# Copyright 2024 hirmiura (https://github.com/hirmiura)

from __future__ import annotations

import argparse
import re
import sys
import tomllib
from logging import DEBUG, StreamHandler, getLogger
from pathlib import Path
from typing import Any

import polib

logger = getLogger(__name__)
handler = StreamHandler(sys.stderr)
handler.setLevel(DEBUG)
logger.setLevel(DEBUG)
logger.addHandler(handler)
logger.propagate = False


DEFAULT_CONFIG_FILE = "potrans.toml"
conf: dict[str, Any] = {}


def procee_args() -> argparse.Namespace:
    """コマンドライン引数を処理する

    Returns:
        argparse.Namespace: 処理した引数
    """
    parser = argparse.ArgumentParser(description="poファイルを正規表現ルールに従って翻訳する")
    parser.add_argument(
        "-c",
        "--conf",
        default=DEFAULT_CONFIG_FILE,
        help=f"設定ファイル。デフォルト「{DEFAULT_CONFIG_FILE}」",
    )
    parser.add_argument(metavar="FILES", dest="files", nargs="+", help="対象ファイル")
    parser.add_argument(
        "-i", "--inplace", action="store_true", help="ファイルをインプレース処理で編集します"
    )
    parser.add_argument("--version", action="version", version="%(prog)s 0.1.0")
    args = parser.parse_args()

    global conf
    conf["files"] = args.files
    conf["inplace"] = args.inplace
    cf = Path(args.conf)
    with cf.open("rb") as cfp:
        toml = tomllib.load(cfp)
    conf |= toml
    return args


def procee() -> int:
    """処理の大元となる関数

    Returns:
        int: 成功時は0を返す
    """
    for file in conf["files"]:
        pofile = polib.pofile(file)
        for entry in pofile:
            for rule in conf["rules"]:
                match = rule["msgid"].match(entry.msgid)
                if match:
                    entry.msgstr = rule["msgid"].sub(rule["msgstr"], entry.msgid)
                    break
        if conf["inplace"]:
            pofile.save(file)
        else:
            print(str(pofile))
    return 0


def compile_regex() -> None:
    for rule in conf["rules"]:
        rule["msgid"] = re.compile(rule["msgid"], re.IGNORECASE)


def main() -> int:
    """メイン関数

    Returns:
        int: 成功時は0を返す
    """
    procee_args()
    compile_regex()
    return procee()


if __name__ == "__main__":
    sys.exit(main())
