DEST = $(HOME)/tmp/obj/$(subst $(HOME)/src,,$(PWD))
tout: $(DEST)/reveil $(DEST)/notif $(DEST)/reve
	
$(DEST)/notif: notif.c
	cc -o $@ $^ -framework CoreFoundation

$(DEST)/reve: reveil.c
	cc -o $@ $^ -framework IOKit -framework CoreFoundation

$(DEST)/reveil : reveil
	cp $^ $@
