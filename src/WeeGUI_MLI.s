;
;  WeeGUI_MLI.s
;  Machine Language API for WeeGUI
;
;  Created by Quinn Dunki on 8/15/14.
;  Copyright (c) 2014 One Girl, One Laptop Productions. All rights reserved.
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Reserved zero page locations
;
PARAM0					= $06
PARAM1					= $07
PARAM2					= $08
PARAM3					= $09



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WeeGUI entry point
; Set up your call, then do a JSR to this address.
;
WeeGUI					= $4004		; Offset of WGDispatch from 4000


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; API call names, to be passed to WeeGUI via X register
; e.g.
;     ldx #WGDesktop
;     jsr WeeGUI
;
WGClearScreen			= 0
WGDesktop				= 2
WGSetCursor				= 4
WGSetGlobalCursor		= 6
WGSyncGlobalCursor		= 8
WGPlot					= 10
WGPrint					= 12
WGFillRect				= 14
WGStrokeRect			= 16
WGFancyRect				= 18
WGPaintView				= 20
WGViewPaintAll			= 22
WGEraseViewContents		= 24
WGCreateView			= 26
WGCreateCheckbox		= 28
WGCreateButton			= 30
WGViewSetTitle			= 32
WGViewSetAction			= 34
WGSelectView			= 36
WGViewFromPoint			= 38
WGViewFocus				= 40
WGViewUnfocus			= 42
WGViewFocusNext			= 44
WGViewFocusPrev			= 46
WGViewFocusAction		= 48
WGPendingViewAction		= 50
WGPendingView			= 52
WGScrollX				= 54
WGScrollXBy				= 56
WGScrollY				= 58
WGScrollYBy				= 60
WGEnableMouse			= 62
WGDisableMouse			= 64
WGDeleteView			= 66
WGEraseView				= 68
WGExit					= 70
WGCreateProgress		= 72
WGSetState				= 74
WGViewSetRawTitle		= 76
WGSetContentWidth		= 78
WGSetContentHeight		= 80
WGStrokeRoundRect		= 82
WGCreateRadio			= 84

