# FlutPlayer
> 음원을 재생하는 Android / Windows 애플리케이션입니다.

![example](example.png)

- 오디오
	- 재생 슬라이더
	- 재생 / 일시정지
	- 다음 트랙 이동, 이전 트랙 이동
	- 셔플, 반복 재생 모드
	- mashup 모드
	- 볼륨 조절
- 재생 목록
	- 목록 정렬, 목록 초기화
	- 음원 이동 (드래그 앤 드랍)
	- 음원 제거 (스와이프)
- 태그
	- 선택한 태그를 재생 목록으로 불러오기
	- 태그 추가, 업데이트, 삭제
	- 태그 즐겨찾기 기능
	- 데이터베이스 저장
- 이퀄라이저
	- 밴드의 게인 값 조절
	- 스무스 슬라이더 이동
- 배경
	- 로컬 파일 내 배경 파일 선택 가능
	- 이미지 배경 회전, 확대/축소, 색상 필터링 여부 설정
	- 배경 밝기 조절
	- 기본 애니메이션 백그라운드
- NCS(NoCopyrightSounds) 비주얼라이저
	- 15가지 색상 설정
- 설정
	- 태그, 정렬, mashup, 이퀄라이저, 배경, 비주얼라이저
	- 데이터베이스, CSV 파일 내보내기 / 불러오기
- 기타
	- 백그라운드 프로세스 지원
	- 알림바 UI 제공

## Stack
- Flutter

### Dependency
- just_audio: ^0.9.35
- audioplayers: ^5.2.0
- file_picker: ^6.0.0
- permission_handler: ^11.0.1
- audio_service: ^0.18.12
- sqflite: ^2.3.0
- sqflite_common_ffi: ^2.3.0
- shared_preferences: ^2.2.2
- video_player: ^2.8.2

## File Structure
```
app/
├── components/: 기능 UI 위젯
├── models/: 클래스, 상수 데이터
├── screens/: 레이아웃 UI 위젯
├── utils/: 유틸리티 클래스 및 메서드
├── widgets/: 공통 위젯
├── global.dart: 전역 프로퍼티 & 메서드
└── main_page.dart: 메인 레이아웃 UI
```
