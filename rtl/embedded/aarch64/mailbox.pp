unit mailbox;

interface

type
    TMBox = bitpacked Array[0..36] of DWord;

var
    MBox: TMBox;

const
    MBOX_REQUEST    = 0;

    { Channels }
    MBOX_CH_POWER   = 0;
    MBOX_CH_FB      = 1;
    MBOX_CH_VUART   = 2;
    MBOX_CH_VCHIQ   = 3;
    MBOX_CH_LEDS    = 4;
    MBOX_CH_BTNS    = 5;
    MBOX_CH_TOUCH   = 6;
    MBOX_CH_COUNT   = 7;
    MBOX_CH_PROP    = 8;

    { Tags }
    MBOX_TAG_GETSERIAL     = $10004;
    MBOX_TAG_SETCLKRATE    = $38002;
    MBOX_TAG_LAST          = 0;

    { Responses }
    MBOX_RESPONSE   = $80000000;
    MBOX_FULL       = $80000000;
    MBOX_EMPTY      = $40000000;

    { Mailbox offsets from PeripheralBase }
    VIDEOCORE_MBOX  = $0000B880;
    MBOX_READ       = $0;
    MBOX_POLL       = $10;
    MBOX_SENDER     = $14;
    MBOX_STATUS     = $18;
    MBOX_CONFIG     = $1C;
    MBOX_WRITE      = $20;

function MailboxCall(BaseAddr: DWord; Channel: DWord): DWord;

implementation

uses
    mmio;

function MailboxCall(BaseAddr: DWord; Channel: DWord): DWord;
var
    MBoxPtr: Pointer;
    R: PtrUint;
    MboxAddr: DWord;
begin
    MboxAddr := BaseAddr + VIDEOCORE_MBOX;

    MBoxPtr := Addr(MBox);

    while True do
    begin
        DUMMY(1);
        if (GET32(MboxAddr + MBOX_STATUS) and MBOX_FULL) = 0 then break;
    end;

    { Join the address and channel together to identify our message }
    R := (PtrUint(MBoxPtr) and (not $0F)) or (Channel and $0F);

    { Write to the mailbox - put the address of our message on the mailbox }
    PUT32(MboxAddr + MBOX_WRITE, R);

    while True do
    begin
        DUMMY(1);
        { Are there any messages pending in the mailbox? }
        if (GET32(MboxAddr + MBOX_STATUS) and MBOX_EMPTY) > 0 then continue;

        { Is it a response to our message? }
        if (GET32(MboxAddr + MBOX_READ) = R) then
        begin
            Exit(MBox[1]);
        end;
    end;

    MailboxCall := 0;
end;

end.