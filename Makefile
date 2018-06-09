CC ?= gcc

CFLAGS += -std=c99 -W -Wall -pedantic -ftree-vectorize -fPIE \
	-fstack-protector -O3 -D_FORTIFY_SOURCE=2 \
	-Ideps/lodepng \
	-D_POSIX_C_SOURCE=200809L \
	-D_FILE_OFFSET_BITS=64 \
	-DLODEPNG_NO_COMPILE_ANCILLARY_CHUNKS \
	-DLODEPNG_NO_COMPILE_CPP \
	-DLODEPNG_NO_COMPILE_ALLOCATORS

LDFLAGS += -pie
ifeq ($(shell uname -s),Linux)
# Full RELRO
LDFLAGS += -Wl,-z,now -Wl,-z,relro
endif

PREFIX := /usr/local

all : png2pos

man : png2pos.1.gz

.PHONY : clean install uninstall

clean :
	@-rm -f *.o png2pos deps/lodepng/*.o
	@-rm -f *.pos *.gz debug.* *.backup
	@-rm -f *.c_ *.h_

install : all man
	mkdir -p $(DESTDIR)$(PREFIX)/bin $(DESTDIR)$(PREFIX)/share/man/man1
	install -m755 png2pos $(DESTDIR)$(PREFIX)/bin/
	install -m644 png2pos.1.gz $(DESTDIR)$(PREFIX)/share/man/man1/
	[ -d /etc/bash_completion.d/ ] && install -m644 png2pos.complete /etc/bash_completion.d/png2pos

uninstall :
	rm -f $(DESTDIR)$(PREFIX)/bin/png2pos
	rm -f $(DESTDIR)$(PREFIX)/share/man/man1/png2pos.1.gz
	rm -f /etc/bash_completion.d/png2pos

png2pos : png2pos.o deps/lodepng/lodepng.o
	@printf "%-16s%s\n" LD $@
	@$(CC) $^ $(LDFLAGS) -o $@
	@-strip $@

%.o : %.c
	@printf "%-16s%s\n" CC $@
	@$(CC) -c $(CFLAGS) -o $@ $<

deps/lodepng/%.o : deps/lodepng/%.cpp
	@printf "%-16s%s\n" CC $@
	@$(CC) -x c -c $(CFLAGS) -o $@ $<

# man page
%.1.gz : %.1
	@printf "%-16s%s\n" GZIP $@
	@gzip -c -9 $< > $@

# static version
# usually used with musl etc.:
#   CC=/usr/local/musl/bin/musl-gcc make static
static : CFLAGS += -static -fno-PIE
static : LDFLAGS += -static -no-pie
static : all

# debugging
debug : CFLAGS += -DDEBUG
debug : all
	@ls -l png2pos
	@./png2pos -V

# git update
update :
	git pull --recurse-submodules

# code indentation
indent : png2pos.c_ seccomp.h_

%.h_ : %.h
%.c_ : %.c
	@printf "%-16s%s\n" INDENT $@
	@indent \
	    --ignore-profile \
	    --indent-level 4 \
	    --line-comments-indentation 0 \
	    --case-indentation 4 \
	    --no-tabs \
	    --line-length 76 \
	    --ignore-newlines \
	    --blank-lines-after-declarations \
	    --blank-lines-after-procedures \
	    --blank-lines-before-block-comments \
	    --braces-on-if-line \
	    --braces-on-func-def-line \
	    --braces-on-struct-decl-line \
	    --break-before-boolean-operator \
	    --cuddle-do-while \
	    --cuddle-else \
	    --dont-break-procedure-type \
	    --format-all-comments \
	    --indent-label 0 \
	    --no-space-after-function-call-names \
	    --swallow-optional-blank-lines \
	    --dont-line-up-parentheses \
	    --no-comment-delimiters-on-blank-lines \
	    -v $< -o $@
