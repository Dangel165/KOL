# KOL
Korean Locale Setup Script

## 지원 OS

- **Kali Linux** (모든 버전)
- **Ubuntu** (18.04 이상)
- **Raspberry Pi OS** (Raspbian)
- **Debian** 기반 배포판

## Wayland 지원

### 자동 감지 기능
스크립트는 현재 디스플레이 서버를 자동으로 감지합니다:
- Wayland 세션 자동 인식
- X11 세션 자동 인식
- 최적화된 입력기 자동 선택

### Wayland 최적화
- **GNOME + Wayland**: ibus (네이티브 Wayland 지원)
- **KDE + Wayland**: fcitx5 (향상된 Wayland 호환성)
- **기타 + Wayland**: fcitx5 (범용 Wayland 지원)

### 환경 변수 자동 설정
Wayland 환경에서 한국어 입력을 위한 환경 변수가 자동으로 설정됩니다:
```bash
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=ibus
```

## 설치 방법

### 1. 스크립트 다운로드
```bash
# Git으로 다운로드하거나 직접 파일 복사
chmod +x korean_locale_setup.sh
```

### 2. 실행
```bash
sudo ./korean_locale_setup.sh
```

### 3. 메뉴에서 선택
```
=== 설치 옵션 ===
1) 전체 설치 (권장)
2) 기본 설치 (언어팩 + 폰트)
3) 최소 설치 (언어팩만)
4) 사용자 정의 설치
5) OS별 설치
6) 설치 상태 확인
7) 제거
0) 종료
```

### 4. 재부팅
```bash
sudo reboot
```

## 설치 옵션 설명

### 1. 전체 설치 (권장)
모든 구성 요소를 설치합니다:
- 한국어 언어팩
- 한국어 폰트 (나눔, Noto CJK 등)
- 한국어 입력기 (Wayland/X11 자동 선택)
- 추가 도구 (LibreOffice, Firefox 한국어팩)
- 타임존 설정 (Asia/Seoul)

### 2. 기본 설치
필수 구성 요소만 설치:
- 한국어 언어팩
- 한국어 폰트
- 한국어 입력기

### 3. 최소 설치
언어팩만 설치 (폰트 및 입력기 제외)

### 4. 사용자 정의 설치
원하는 구성 요소를 선택하여 설치

### 5. OS별 설치
특정 OS에 최적화된 설치:
## 설치되는 항목

### 1. 한국어 언어팩
- `language-pack-ko`
- `language-pack-ko-base`
- `language-pack-gnome-ko` (우분투)

### 2. 한국어 폰트
- **나눔 폰트**: fonts-nanum, fonts-nanum-coding, fonts-nanum-extra
- **Noto CJK**: fonts-noto-cjk, fonts-noto-cjk-extra
- **백묵 폰트**: fonts-baekmuk
- **은 폰트**: fonts-unfonts-core

### 3. 한국어 입력기

#### Wayland 환경
- **GNOME**: ibus + ibus-hangul
- **KDE**: fcitx5 + fcitx5-hangul
- **기타**: fcitx5 + fcitx5-hangul

#### X11 환경
- **GNOME**: ibus + ibus-hangul
- **KDE**: fcitx + fcitx-hangul
- **기타**: ibus + ibus-hangul

### 4. 추가 도구 (전체 설치 시)
- hunspell-ko (맞춤법 검사)
- aspell-ko (철자 검사)
- mythes-ko (유의어 사전)
- libreoffice-l10n-ko (LibreOffice 한국어팩)
- firefox-locale-ko (Firefox 한국어팩)

### 5. 로케일 설정
```
LANG=ko_KR.UTF-8
LC_ALL=ko_KR.UTF-8
LANGUAGE=ko_KR:ko
```

## 한국어 입력 설정

### Wayland 환경

#### GNOME (Wayland)
1. 설정 > 키보드 > 입력 소스
2. "+" 버튼 클릭
3. "한국어" 선택
4. "한국어 (Hangul)" 추가
5. 한/영 전환: Shift+Space 또는 Super+Space

#### KDE (Wayland)
```bash
fcitx5-configtool
```
1. 입력 메서드 탭
2. "추가" 버튼 클릭
3. "Hangul" 검색 및 추가
4. 한/영 전환: Ctrl+Space

### X11 환경

#### GNOME (X11)
```bash
ibus-setup
```
1. Input Method 탭
2. "Add" 버튼 클릭
3. "Korean" > "Hangul" 선택
4. 한/영 전환: Shift+Space

#### KDE (X11)
```bash
fcitx-config-gtk
```
1. 입력기 탭
2. "+" 버튼으로 Hangul 추가
3. 한/영 전환: Ctrl+Space

## 설치 상태 확인

### 스크립트 내장 확인 기능
```bash
sudo ./korean_locale_setup.sh
# 메뉴에서 "6) 설치 상태 확인" 선택
```

PS:사실 깔기 겁나 귀찮아서 만든겁니다
