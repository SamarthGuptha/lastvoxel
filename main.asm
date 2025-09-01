extern GetModuleHandleA
extern RegisterClassExA
extern CreateWindowExA
extern DefWindowProcA
extern GetDC
extern ReleaseDC
extern SetPixel
extern ShowWindow
extern UpdateWindow
extern DestroyWindow
extern PostQuitMessage
extern PeekMessageA
extern TranslateMessage
extern BeginPaint
extern DispatchMessageA
extern BeginPaint
extern EndPaint
extern GetClientRect
extern CreateCompatibleDC
extern CreateCompatibleBitmap
extern SelectObject
extern DeleteDC
extern FillRect
extern BitBlt
extern CreateSolidBrush
extern ExitProcess

%define W_WIDTH     800
%define W_HEIGHT    600
%define W_CENTER_X  (W_WIDTH/2)
%define W_CENTER_Y  (W_HEIGHT/2)

%define NUM_STARS   2048
%define STAR_SPEED  2.0

%define IDI_APPLICATION 32512
%define IDC_ARROW       32514
%define CW_USEDEFAULT   0x80000000
%define WS_OVERLAPPED   0x00000000
%define WS_CAPTION      0x00C00000
%define WS_SYSMENU      0x00080000
%define WS_MINIMIZEBOX  0x00020000
%define WS_VISIBLE      0x10000000
%define CS_HREDRAW      0x0002
%define CS_VREDRAW      0x0001
%define SW_SHOWNORMAL   1
%define PM_REMOVE       0x0001
%define WM_CREATE       0x0001
%define WM_PAINT        0x000F
%define WM_CLOSE        0x0010
%define WM_DESTROY      0x0002
%define WM_QUIT         0x0012
%define BLACK_BRUSH     4
%define SRCCOPY         0x00CC0020

struc WNDCLASSEXA
    .cbSize:         resd 1
    .style:          resd 1
    .lpfnWndProc:    resq 1
    .cbClsExtra:     resd 1
    .cbWndExtra:     resd 1
    .hInstance:      resq 1
    .hIcon:          resq 1
    .hCursor:        resq 1
    .hbrBackground:  resq 1
    .lpszMenuName:   resq 1
    .lpszClassName:  resq 1
    .hIconSm:        resq 1
endstruc

struc MSG
    .hwnd:           resq 1
    .message:        resd 1
    .padding:        resd 1
    .wParam:         resq 1
    .lParam:         resq 1
    .time:           resd 1
    .pt_x:           resd 1
    .pt_y:           resd 1
endstruc
struc PAINTSTRUC
    .hdc:            resq 1
    .fErase:         resd 1
    .padding:        resq 1
    .rcPaint:        resd 4
    .fRestore:       resd 1
    .fIncUpdate:     resd 1
    .rgbReserved:    resb 32
endstruc

struc RECT
    .left:           resd 1
    .top:            resd 1
    .right:          resd 1
    .bottom:         resd 1
endstruc
struc Star
    .x:              resd 1
    .y:              resd 1
    .z:              resd 1
endstruc

;datasection
section .data
    szClassName     db 'LastVoxelClass', 0
    szWindowName    db 'The Last Voxel - Scene One The Awakening', 0
    rand_seed       dd 0xCAFEBABE

    f_half          dd 0.5
    f_one           dd 1.0
    f_255           dd 255.0
    f_speed         dd STAR_SPEED
    f_width         dd W_WIDTH*1.0
    f_height        dd W_HEIGHT*1.0
section .bss
    hInstance       resq 1
    hWnd            resq 1
    wndClass        resb WNDCLASSEXA_size
    msg             resb MSG_SIZE
    ps              resb PAINTSTRUCT_size
    rc              resb RECT_size

    hMemDC          resq 1
    hBitmap         resq 1
    hOldBitmap      resq 1
    hBlackBrush     resq 1

    stars           resb Star_size*NUM_STARS
;codesec
section .text
global main

main:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32

    xor     rcx, rcx
    call    GetModuleA
    mov     [hInstance], rax

    mov     qword [wndClass + WNDCLASSEXA.hInstance], rax
    mov     qword [wndClass + WNDCLASSEXA.lpszClassName], szClassName
    mov     qword [wndClass + WNDCLASSEXA.lpfnWndProc], WndProc
    mov     qword [wndClass + WNDCLASSEXA.style], CS_HREDRAW | CS_VREDRAW
    mov     qword [wndClass + WNDCLASSEXA.cbSize], WNDCLASSEXA_size
    mov     qword [wndClass + WNDCLASSEXA.hbrBackground], BLACK_BRUSH + 1

    xor     rcx, rcx
    mov     rdx, IDI_APPLICATION
    call    LoadIconA
    mov     [wndClass + WNDCLASSEXA.hIcon], rax
    mov     [wndClass + WNDCLASSEXA.hIconSm], rax

    xor     rcx, rcx
    mov     rdx, IDC_ARROW
    call    LoadCursorA
    mov     [wndClass + WNDCLASSEXA.hCursor], rax

    ;register
    lea     rcx, [wndClass]
    call    RegisterClassExA
    ;windowcreation
    mov     r9, qword [hInstance]
    xor     r8, r8
    mov     rdx, szWindowName
    lea     rcx, [szClassName]
    push    0
    push    0
    push    r9
    push    WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX | WS_VISIBLE
    sub     rsp, 32
    mov     dword [rsp+48], W_HEIGHT
    mov     dword [rsp+40], W_WIDTH
    mov     dword [rsp+32], CW_USEDEFAULT
    mov     dword [rsp+24], CW_USEDEFAULT
    xor     eax, eax
    call    CreateWindowExA
    add     rsp, 32 + (8*4)
    mov     [hWnd], rax

    mov     rcx, [hWnd]
    mov     edx, SW_SHOWNORMAL
    call    ShowWindow

    mov     rcx, [hWnd]
    call    UpdateWindow
    call    init_stars

.animation_loop:
    lea     rcx, [msg]
    xor     rdx, rdx
    xor     r8, r8
    xor     r9, r9
    push    PM_REMOVE
    call    PeekMessageA

    test    eax, eax
    jz      .render_frame

    ;check if msg==WM_QUIT
    cmp     dword [msg+MSG.message], WM_QUIT
    je      .exit_loop

    lea     rcx, [msg]
    call    TranslateMessage
    lea     rcx, [msg]
    call    DispatchMessageA
    jmp     .animation_loop
.render_frame:
    call    draw_scene
    jmp     .animation_loop
.exit_loop
    mov rcx, [hMemDC]
    mov







