unit raspiuart;

{-
    The Raspberry Pi 3 and 4 use an ARM PL011 UART, but requires
    some configuration of the clock via the GPIO before you
    can set the baud rate of the UART and to connect the GPIO
    pins for TX/RX
 -}

interface

procedure UARTInit(BaseAddr: DWord); public name 'UARTInit';
procedure UARTPuts(BaseAddr: DWord; C: Char);
function UARTGet(BaseAddr: DWord): Char;
procedure UARTFlush(BaseAddr: DWord);

implementation

uses
    mailbox, mmio, gpio;

const
    { UART offsets from PeripheralBase }
    UART0_DR       = $00201000;
    UART0_FR       = $00201018;
    UART0_IBRD     = $00201024;
    UART0_FBRD     = $00201028;
    UART0_LCRH     = $0020102C;
    UART0_CR       = $00201030;
    UART0_IMSC     = $00201038;
    UART0_ICR      = $00201044;

procedure SetClockRate(BaseAddr: DWord);
begin
    MBox[0] := 9*4;
    MBox[1] := MBOX_REQUEST;
    MBox[2] := MBOX_TAG_SETCLKRATE;
    MBox[3] := 12;
    MBox[4] := 8;
    MBox[5] := 2;
    MBox[6] := 4000000; { 4 Mhz }
    MBox[7] := 0; { Clear turbo flag }
    MBox[8] := MBOX_TAG_LAST;

    MailboxCall(BaseAddr, MBOX_CH_PROP);
end;

procedure UARTInit(BaseAddr: DWord); public name 'UARTInit';
var
    ra: DWord;
begin
    { Turn off the UART first }
    PUT32(BaseAddr + UART0_CR, 0);

    SetClockRate(BaseAddr);

    { map UART0 to GPIO pins }
    ra := GET32(GPFSEL1);
    ra := ra AND (not (7 shl 12));
    ra := ra OR (4 shl 12);
    PUT32(GPFSEL1, ra);

    PUT32(GPPUD, 0);

    DUMMY(150);

    { Enable pins 14 and 15 }
    ra := ((1 shl 14) or (1 shl 15));
    PUT32(GPPUDCLK0, ra);

    DUMMY(150);

    { Flush GPIO setup }
    PUT32(GPPUDCLK0, 0);

    { Clear interrupts }
    PUT32(BaseAddr + UART0_ICR, $7FF);

    { 115200 baud }
    PUT32(BaseAddr + UART0_IBRD, 2);
    PUT32(BaseAddr + UART0_FBRD, $B);

    { 8n1, enable FIFO }
    PUT32(BaseAddr + UART0_LCRH, ($7 shl 4));

    { Enable rx and tx }
    PUT32(BaseAddr + UART0_CR, $301);
end;

procedure UARTPuts(BaseAddr: DWord; C: Char);
begin
    while True do
    begin
        DUMMY(1);
        if (GET32(BaseAddr + UART0_FR) and $20) = 0 then break;
    end;

    PUT32(BaseAddr + UART0_DR, DWord(C));
end;

function UARTGet(BaseAddr: DWord): Char;
begin
    while True do
    begin
        DUMMY(1);
        if (GET32(BaseAddr + UART0_FR) and $10) = 0 then break;
    end;

    UARTGet := Char(GET32(BaseAddr + UART0_DR));
end;

procedure UARTFlush(BaseAddr: DWord);
begin
    PUT32(BaseAddr + UART0_LCRH, (1 shl 4));
end;

end.