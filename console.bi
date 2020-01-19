#include "SDL2\SDL.bi"

type scrPoint
	as Uint16 char = 32
	as SDL_Color fg, bg
End Type

type console
	public:
    declare constructor (as string, as string, as integer, as integer, as integer, as integer)
    declare sub Quit()
    
    declare sub MoveCursor(as integer, as integer)
    declare sub PrintChar(as Uint16)
    declare sub PrintString overload (as string)
    declare sub PrintString overload (as integer)
    declare sub EndLine()
    declare sub SetColor(as integer, as integer)
    declare sub RefreshScreen()
    declare sub ClearScreen()
    
    declare function GetCursorX() as integer
    declare function GetCursorY() as integer
    declare function GetScreenWidth() as integer
    declare function GetScreenHeight() as integer
	
    private:
    as SDL_Window ptr win
    as SDL_Renderer ptr render
    as SDL_Texture ptr chars
    
    ' Кол-во символов в одной строке изображения
    as integer charsInLine
    ' Ширина и высота символа
   	as integer charW, charH
    
    as integer cursorX, cursorY
    as SDL_Color curForeColor, curBackColor
    as integer maxX, maxY
    
    as scrPoint scr(any,any)
    
    declare function getColor(as integer) as SDL_Color
    declare sub PutChar(as scrPoint, as integer, as integer)
end type

constructor console(windowName as string, path as string, maxX as integer, maxY as integer, charW as integer, charH as integer)	
	this.maxX = maxX
	this.maxY = maxY
	this.charW = charW
	this.charH = charH
	
	redim scr(maxX, maxY)
	
	SDL_Init(SDL_INIT_VIDEO)
	
	win = SDL_CreateWindow(windowName, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, (maxX+1)*charW, (maxY+1)*charH, 0)
	render = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED)
	
	if (win = NULL or render = NULL) then
		print "Error creating render and window."
		Quit()
		return
	EndIf
	
	dim as SDL_Surface ptr surface = SDL_LoadBMP(path)
	
	charsInLine = surface->w\charW
	
	SDL_SetColorKey(surface, SDL_TRUE, SDL_MapRGB(surface->format, 0, 0, 0))
	
	chars = SDL_CreateTextureFromSurface(render, surface)
	
	if (chars = NULL) then
		print "Error loading font."
		Quit()
		end
	EndIf
	
	SDL_FreeSurface(surface)

	' Установить цвет по-умолчанию
	setColor(7,0)
end constructor

sub console.quit()
	SDL_DestroyTexture(chars)
	SDL_DestroyRenderer(render)
	SDL_DestroyWindow(win)
	SDL_Quit()
End sub

sub console.putChar(code as scrPoint, x as integer, y as integer)
	dim as SDL_Rect texturePos = (0, 0, charW-1, charH-1)
	dim as SDL_Rect scrPos = (x*charW, y*charH, charW-1, charH-1)
	dim as SDL_Rect back = (x*charW, y*charH, charW, charH)
	
	' Определить координаты символа на текстуре
	texturePos.x = int(frac(code.char/charsInLine)*charsInLine)*charW
	texturePos.y = int(code.char/charsInLine)*charH
	
	' Отрисовать фон символа
	SDL_SetRenderDrawColor(render, code.bg.r, code.bg.g, code.bg.b, 255)
	SDL_RenderFillRect(render, @back)
	
	' Отрисовать символ
	SDL_SetTextureColorMod(chars, code.fg.r, code.fg.g, code.fg.b)
	SDL_RenderCopy(render, chars, @texturePos, @scrPos)
End Sub

sub console.refreshScreen()
	for y as integer = 0 to maxY
		for x as integer = 0 to maxX
			putChar(scr(x,y), x, y)
		Next
	Next
	
	SDL_RenderPresent(render)
End Sub

sub console.printChar(char as Uint16)
	if cursorX > maxX or cursorX < 0 or cursorY > maxY or cursorY < 0 then return
	
	scr(cursorX, cursorY).char = char
	scr(cursorX, cursorY).fg = curForeColor
	scr(cursorX, cursorY).bg = curBackColor

	cursorX += 1
	
	if cursorX > maxX then endLine()
End Sub

sub console.printString(text as string)
	if cursorY > maxY or cursorY < 0 then return
	
	for i as integer = 0 to len(text)-1
		if text[i] = asc("\") then
			i += 1
			
			select case text[i]
				case asc("n"): ' new line
					endLine()
					continue for
			End Select
		EndIf
		
		if (text[i] >= 192 and text[i] <= 255) then
			printChar(text[i]+64)
		else
			printChar(text[i])
		end if
	Next
End Sub

sub console.printString(value as integer)
	printString(str(value))
End Sub

sub console.setColor(fore as integer, back as integer)
	curForeColor = GetColor(fore)
	curBackColor = GetColor(back)
End Sub

sub console.clearScreen()
	SDL_RenderClear(render)
	
	moveCursor(0,0)
	
	redim scr(maxX, maxY)
End Sub

sub console.endLine()
	cursorY += 1
	cursorX = 0
End Sub

sub console.moveCursor(x as integer, y as integer)
	cursorX = x
	cursorY = y
End Sub

function console.getColor(consoleColor as integer) as SDL_Color
	dim as SDL_Color c = (0,0,0)
	
	select case consoleColor
		case 1: 
			c.b = 128
		case 2:
			c.g = 128
		case 3: 
			c.g = 128 : c.b = 128
		case 4:
			c.r = 128
		case 5:
			c.r = 128 : c.b = 128
		case 6:
			c.r = 128 : c.g = 128
		case 7:
			c.r = 192 : c.g = 192 : c.b = 192
		case 8:
			c.r = 128 : c.g = 128 : c.b = 128
		case 9:
			c.b = 255
		case 10:
			c.g = 255
		case 11:
			c.g = 255 : c.b = 255
		case 12:
			c.r = 255
		case 13:
			c.r = 255 : c.b = 255
		case 14:
			c.r = 255 : c.g = 255
		case 15:
			c.r = 255 : c.g = 255 : c.b = 255
	end select
  
  return c
end function

function console.getCursorX() as integer
	return cursorX
End Function

function console.getCursorY() as integer
	return cursorY
End Function

function console.getScreenWidth() as integer
	return maxX
End Function

function console.getScreenHeight() as integer
	return maxY
End Function