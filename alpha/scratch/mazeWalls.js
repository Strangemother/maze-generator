/*
---
title: Maze Walls (Origin Shift)
files:
    ../point_src/core/head.js
    ../point_src/pointpen.js
    ../point_src/pointdraw.js
    ../point_src/pointlist.js
    ../point_src/point-content.js
    ../point_src/point.js
    ../point_src/events.js
    ../point_src/automouse.js
    ../point_src/distances.js
    ../point_src/dragging.js
    ../point_src/functions/clamp.js
    ../point_src/stage.js
    ../point_src/coupling.js
---

Render the inverted (wall) view of an origin-shift maze export.
Loads the maze JSON, computes walls from edges, and draws them.

 */

const MAZE_JSON_PATH = '../Data/one.json'

class MainStage extends Stage {
    canvas='playspace'

    mounted(){
        this.cellSize = 20
        this.offset = 100
        this.borderLineWidth = 3
        this.borderInnerPadding = 2

        fetch(MAZE_JSON_PATH)
            .then(r => r.json())
            .then(data => {
                this.rows = data.meta.rows
                this.cols = data.meta.cols
                this.walls = data.walls 
                //this.loadMaze(data)
                this.firstDraw(this.ctx)
            });
    }

    loadMaze(data) {
        // this.rows = data.meta.rows
        // this.cols = data.meta.cols

        /* Build a set of open passages for fast lookup. */
        let open = new Set()
        data.edges.forEach(([a, b]) => {
            let lo = Math.min(a, b), hi = Math.max(a, b)
            open.add(lo + '-' + hi)
        })

        /* Compute walls: all adjacent pairs NOT in edges. */
        let walls = []
        let rows = this.rows
            , cols = this.cols
            ;

        /* A wall exists wherever two adjacent cells do NOT share
        an open passage. We check every possible adjacency in the
        grid (right and down only — each boundary appears once)
        and keep those absent from the open set. */
        const tryPush = (a, b)=>{
            if(!open.has(`${a}-${b}`)) { walls.push([a, b]) }
        }

        for(let r = 0; r < rows; r++) {
            for(let c = 0; c < cols; c++) {
                let index = r * cols + c
                /* Right neighbour: same row, next column. */
                if(c + 1 < cols) { tryPush(index, index + 1) };
                /* Down neighbour: same column, next row. */
                if(r + 1 < rows) { tryPush(index, index + cols) };
            }
        }

        return walls
    }

    firstDraw(ctx){
        this.clear(ctx)
        if(!this.walls) { return }
        this.drawWalls(ctx)
        this.drawBorder(ctx)
    }

    draw(){}

    drawWalls(ctx) {
        ctx.strokeStyle = '#999'
        ctx.lineWidth = 2
        ctx.lineCap = 'square';

        ctx.beginPath()
        this.walls.forEach(([a,b])=>{
            let [x1, y1, x2, y2] = this.plotWall(a, b)
            ctx.moveTo(x1, y1)
            ctx.lineTo(x2, y2)
        });
        ctx.stroke()
    }

    plotWall(a,b) {
        /* Return plotting values for the wall between cells a and b.

            let [x1, y1, x2, y2] = this.plotWall(a, b)
            ctx.moveTo(x1, y1)
            ctx.lineTo(x2, y2)
        */
        let diff = b - a
            , row = Math.floor(a / this.cols)
            , col = a % this.cols
            , size = this.cellSize
            , off = this.offset
            ;

        if(diff === 1) {
            /* Vertical wall on the right edge of cell a. */
            let x = off + (col + 1) * size
            let y = off + row * size
            return [x, y, x, y + size]
        }

        /* Horizontal wall on the bottom edge of cell a. */
        let x = off + col * size
        let y = off + (row + 1) * size
        return [x, y, x + size, y]
    }

    drawBorder(ctx) {
        let size = this.cellSize
            , lineWidth = this.borderLineWidth
            , innerPadding = this.borderInnerPadding
            , off = this.offset - (lineWidth * .5) - (innerPadding * .5)
            , w = lineWidth + innerPadding + (this.cols * size) 
            , h = lineWidth + innerPadding + (this.rows * size)
            ;
        ctx.strokeStyle = '#666'
        ctx.lineWidth = lineWidth
        ctx.strokeRect(off, off, w, h)
    }
}


;stage = MainStage.go();
