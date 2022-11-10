import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'notifiers/play_button_notifier.dart';
import 'notifiers/progress_notifier.dart';
import 'notifiers/repeat_button_notifier.dart';

class PageManager {
  final currentSongTitleNotifier = ValueNotifier<String>('');
  final playlistNotifier = ValueNotifier<List<String>>([]);
  final progressNotifier = ProgressNotifier();
  final repeatButtonNotifier = RepeatButtonNotifier();
  final isFirstSongNotifier = ValueNotifier<bool>(true);
  final playButtonNotifier = PlayButtonNotifier();
  final isLastSongNotifier = ValueNotifier<bool>(true);
  final isShuffleModeEnabledNotifier = ValueNotifier<bool>(false);

  late AudioPlayer _audioPlayer;
  late ConcatenatingAudioSource _playlist;

  PageManager() {
    _init();
  }

  void _init() async {
    _audioPlayer = AudioPlayer();
    _setInitialPlaylist();
    _listenForChangesInPlayerState();
    _listenForChangesInPlayerPosition();
    _listenForChangesInBufferedPosition();
    _listenForChangesInTotalDuration();
    _listenForChangesInSequenceState();
  }

  void _setInitialPlaylist() async {
    //const prefix = 'https://www.soundhelix.com/examples/mp3';
    final song1 = Uri.parse(
        'https://music.я.ws/public/play_song.php?id=474499229_456732307&hash=ffd9d4c51f24d6f356c4ee76c489c6d0ec086f644faebf8035d76ea112d21706&artist=Miyagi%20%26amp%3B%20%D0%AD%D0%BD%D0%B4%D1%88%D0%BF%D0%B8%D0%BB%D1%8C&title=%D0%9D%D0%B5%20%D1%82%D0%B5%D1%80%D1%8F%D1%8F');
    final song2 = Uri.parse(
        'https://music.я.ws/public/play_mp3.php?id=6847&hash=f78893e3719fdf102312528dccc4d316efc1a962d89c7205af1fd840ab8d504d&artist=xxxtentacion&title=jocelyn-flores');
    final song3 = Uri.parse(
        'https://music.я.ws/public/play_mp3.php?id=51478&hash=345a869b2e073e18ef2b6569c38d4ff3269fb867e3d79d30b18b5a36c05043f3&artist=nirvana&title=smells-like-teen-spirit');
    final song4 = Uri.parse(
        'https://music.я.ws/public/play_song.php?id=561444398_456239732&hash=6da2041b459be8df7926d23d6108c95302c67aad65591232040d5a2450c64fca&artist=%E2%96%B8Ed%20Sheeran&title=%E2%98%85%20Perfect');
    final song5 = Uri.parse(
        'https://music.я.ws/public/play_mp3.php?id=3425&hash=006d13a438980565e08ba67f82e3bf9eaf806c5357a4270b65a6dda638d86e05&artist=xxxtentacion&title=moonlight');
    final song6 = Uri.parse(
        'https://music.я.ws/public/play_mp3.php?id=5765&hash=33c76ca25915432de84064a883e145c3c653409e1a315a95e59153c35978ee26&artist=mary-gu&title=%D0%BD%D0%B5%D0%BD%D0%B0%D0%B2%D0%B8%D0%B6%D1%83-%D0%B3%D0%BE%D1%80%D0%BE%D0%B4%D0%B0');
    final song7 = Uri.parse(
        'https://music.я.ws/public/play_mp3.php?id=59889&hash=f549ec620bd0198e844f3f4c4393401b9f0358b1c65ecceda1f74ffea702a9e8&artist=INSTASAMKA&title=moneyken-love');
    _playlist = ConcatenatingAudioSource(children: [
      AudioSource.uri(song1, tag: 'Miyagi & Эндшпиль - Не теряя'),
      AudioSource.uri(song2, tag: 'XXXTENTACION - Jocelyn Flores'),
      AudioSource.uri(song3, tag: 'Nirvana - Smells Like Teen Spirit'),
      AudioSource.uri(song4, tag: 'Ed Sheeran - Perfect'),
      AudioSource.uri(song5, tag: 'XXXTENTACION - Moonlight'),
      AudioSource.uri(song6, tag: 'Мари Гу - Ненавижу город'),
      AudioSource.uri(song7, tag: 'INSTASAMKA - Moneyken Love'),
    ]);
    await _audioPlayer.setAudioSource(_playlist);
  }

  void _listenForChangesInPlayerState() {
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        playButtonNotifier.value = ButtonState.loading;
      } else if (!isPlaying) {
        playButtonNotifier.value = ButtonState.paused;
      } else if (processingState != ProcessingState.completed) {
        playButtonNotifier.value = ButtonState.playing;
      } else {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }
    });
  }

  void _listenForChangesInPlayerPosition() {
    _audioPlayer.positionStream.listen((position) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: position,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });
  }

  void _listenForChangesInBufferedPosition() {
    _audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: bufferedPosition,
        total: oldState.total,
      );
    });
  }

  void _listenForChangesInTotalDuration() {
    _audioPlayer.durationStream.listen((totalDuration) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: totalDuration ?? Duration.zero,
      );
    });
  }

  void _listenForChangesInSequenceState() {
    _audioPlayer.sequenceStateStream.listen((sequenceState) {
      if (sequenceState == null) return;

      // update current song title
      final currentItem = sequenceState.currentSource;
      final title = currentItem?.tag as String?;
      currentSongTitleNotifier.value = title ?? '';

      // update playlist
      final playlist = sequenceState.effectiveSequence;
      final titles = playlist.map((item) => item.tag as String).toList();
      playlistNotifier.value = titles;

      // update shuffle mode
      isShuffleModeEnabledNotifier.value = sequenceState.shuffleModeEnabled;

      // update previous and next buttons
      if (playlist.isEmpty || currentItem == null) {
        isFirstSongNotifier.value = true;
        isLastSongNotifier.value = true;
      } else {
        isFirstSongNotifier.value = playlist.first == currentItem;
        isLastSongNotifier.value = playlist.last == currentItem;
      }
    });
  }

  void play() async {
    _audioPlayer.play();
  }

  void pause() {
    _audioPlayer.pause();
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  void dispose() {
    _audioPlayer.dispose();
  }

  void onRepeatButtonPressed() {
    repeatButtonNotifier.nextState();
    switch (repeatButtonNotifier.value) {
      case RepeatState.off:
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
      case RepeatState.repeatSong:
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case RepeatState.repeatPlaylist:
        _audioPlayer.setLoopMode(LoopMode.all);
    }
  }

  void onPreviousSongButtonPressed() {
    _audioPlayer.seekToPrevious();
  }

  void onNextSongButtonPressed() {
    _audioPlayer.seekToNext();
  }

  void onShuffleButtonPressed() async {
    final enable = !_audioPlayer.shuffleModeEnabled;
    if (enable) {
      await _audioPlayer.shuffle();
    }
    await _audioPlayer.setShuffleModeEnabled(enable);
  }

  void addSong() {
    final songNumber = _playlist.length + 1;
    const prefix = 'https://www.soundhelix.com/examples/mp3';
    final song = Uri.parse('$prefix/SoundHelix-Song-$songNumber.mp3');
    _playlist.add(AudioSource.uri(song, tag: 'Song $songNumber'));
  }

  void removeSong() {
    final index = _playlist.length - 1;
    if (index < 0) return;
    _playlist.removeAt(index);
  }
}
