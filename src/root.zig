// Copyright 2025 Eduardo Antunes dos Santos Vieira
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

pub const Instruction = struct {
    x: u8,
    y: u8,
    n: u8,
    arg: u8,
    addr: u16,
    op: Operation,

    pub fn decodeFrom(code: u16) Instruction {
        return .{
            .x = @truncate((code & 0xF00) >> 8),
            .y = @truncate((code & 0xF0) >> 4),
            .n = @truncate(code & 0xF),
            .arg = @truncate(code & 0xFF),
            .addr = code & 0xFFF,
            .op = decode(code),
        };
    }
};

const Operation = enum {
    unknown, // sentinel for invalid operation
    call,    // calls subroutine at address
    rts,     // returns from subroutine
    jump,    // unconditional jump to address
    jump0,   // unconditional jump to address + v0
    ske,     // skips if VX equals argument
    skne,    // skips if VX doesn't equal argument
    skre,    // skips if VX equals VY
    skrne,   // skips if VX doesn't equal VY
    skpr,    // skips if key corresponding to VX is pressed
    sknpr,   // skips if key corresponding to VX is not pressed
    keyd,    // waits for a key press, then store it in VX
    load,    // loads argument into VX
    loadi,   // loads address into index
    loadd,   // loads the value of VX to delay timer
    loads,   // loads the value of VX to sound timer
    ldchr,   // points index to the character sprite of VX
    move,    // moves value from VY to VX
    moved,   // moves value from delay timer to VX
    or_,     // VY |= VX
    and_,    // VY &= VX
    xor,     // VY ^= VX
    add,     // adds argument to VX
    addr,    // add VY to VX, setting flag on carry
    addi,    // adds VX to index
    sub,     // VX -= VY, clearing flag on borrow
    rsub,    // VX = VY - VX, clearing flag on borrow
    shr,     // shifts VX to the right
    shl,     // shifts VX to the left
    rand,    // puts random number into VX
    cls,     // clears the screen
    draw,    // draws stuff to the screen using VX, VY and n
    bcd,     // converts VX to BCD and stores it in RAM, where the index points
    store,   // stores registers into memory
    read,    // reads registers from memory
};

fn decode(code: u16) Operation {
    const op: u8 = @truncate(code >> 12);
    return switch (op) {
        0x0 => switch(code) {
            0x00E0 => .cls,
            0x00EE => .rts,
            else => .unknown,
        },
        0x1 => .jump,
        0x2 => .call,
        0x3 => .ske,
        0x4 => .skne,
        0x5 => .skre,
        0x6 => .load,
        0x7 => .add,
        0x8 => decodeArithmetic(code),
        0x9 => .skrne,
        0xA => .loadi,
        0xB => .jump0,
        0xC => .rand,
        0xD => .draw,
        0xE => decodeKeypad(code),
        0xF => decodeMisc(code),
        else => .unknown,
    };
}

fn decodeArithmetic(code: u16) Operation {
    const op: u8 = @truncate(code & 0xF);
    return switch (op) {
        0x0 => .move,
        0x1 => .or_,
        0x2 => .and_,
        0x3 => .xor,
        0x4 => .addr,
        0x5 => .sub,
        0x6 => .shr,
        0x7 => .rsub,
        0xE => .shl,
        else => .unknown,
    };
}

fn decodeKeypad(code: u16) Operation {
    const op: u8 = @truncate(code & 0xFF);
    return switch (op) {
        0x9E => .skpr,
        0xA1 => .sknpr,
        else => .unknown,
    };
}

fn decodeMisc(code: u16) Operation {
    const op: u8 = @truncate(code & 0xFF);
    return switch (op) {
        0x07 => .moved,
        0x0A => .keyd,
        0x15 => .loadd,
        0x18 => .loads,
        0x1E => .addi,
        0x29 => .ldchr,
        0x33 => .bcd,
        0x55 => .store,
        0x65 => .read,
        else => .unknown,
    };
}
