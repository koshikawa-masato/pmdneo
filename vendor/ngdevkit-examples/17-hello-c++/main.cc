/*
 * Copyright (c) 2025 Damien Ciabrini
 * This file is part of ngdevkit
 *
 * ngdevkit is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * ngdevkit is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with ngdevkit.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <ngdevkit/neogeo.h>
#include <ngdevkit/ng-fix.h>
#include <cstdio>


class Asset {
    int force;
public:
    Asset(int f) : force(f) {
    }
    int getForce() {
        return this->force;
    }
};

// Example of global initialization, object is constructed
// before main() is called
Asset asset(10);


class Game {
    static constexpr u16 palette[] = {0x8000, 0x0fff, 0x0555};
    static constexpr char hello1[] = "Hello NEO-GEO from C++!";
    static constexpr char hello2[] = "https://github.com/dciabrin/ngdevkit";
    u8 value;

 public:
    Game(u8 value) {
        this->value = value;
    }

    void setup(void) {
        ng_cls();
        for (u8 i=0; i<3; i++) {
            MMAP_PALBANK1[i]=palette[i];
        }
    }

    void loop(void) {
        char buf[30];
        ng_text((42-sizeof(hello1))/2, 11, 0, hello1);
        ng_text((42-sizeof(hello2))/2, 13, 0, hello2);

        snprintf(buf, 30, "game address: %p", this);
        ng_text(9, 18, 0, buf);
        snprintf(buf, 30, "game value: %d", this->value);
        ng_text(9, 19, 0, buf);

        snprintf(buf, 30, "asset address: %p", &asset);
        ng_text(9, 22, 0, buf);
        snprintf(buf, 30, "asset value: %d", asset.getForce());
        ng_text(9, 23, 0, buf);

        for(;;) {}
    }
};


int main(int argc, char*argv[]) {
    Game game(42);
    game.setup();
    game.loop();
    return 0;
}
