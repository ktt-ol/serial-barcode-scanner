all: audio

audio: main.vala audio.vala audio-interface.vala
	valac -o $@ --pkg gstreamer-0.10 --pkg gio-2.0 $^

clean:
	rm -rf audio

.PHONY: all clean
