import derelict.sdl2.sdl;


class Button {
	this(void delegate() action) {
		act = action;
	}

	abstract void render(SDL_Surface *s, int x, int y);
	abstract bool mouseOver(int x, int y);
	
	void delegate() act;
}

class RectangleButton : Button {
	this(void delegate() action, SDL_Rect r, int c, int ch) {
		super(action);
		rect = r;
		color = c;
		colorHighlight = ch;
	}
	
	SDL_Rect rect;
	int color, colorHighlight;
	
	override void render(SDL_Surface *s, int x, int y) {
		if (!mouseOver(x,y))
			SDL_FillRect(s, &rect, color);
		else
			SDL_FillRect(s, &rect, colorHighlight);
	}
	
	override bool mouseOver(int x,int y) {
		return rect.x <= x && x <= rect.x + rect.w && rect.y <= y && y <= rect.y + rect.h;
	}
}