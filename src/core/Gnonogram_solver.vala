/* Solves simple nonograms for gnonograms-elementary
 * Copyright (C) 2012-2017  Jeremy Wootten
 *
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Author:
 *  Jeremy Wootten <jeremy@elementaryos.org>
 */

namespace Gnonograms {

 //~ public class Solver {

  //~ private int rows;
  //~ private int cols;
  //~ private int regionCount;
  //~ private Controller control;
  //~ public My2DCellArray grid, solution;
  //~ private Region[] regions;
  //~ private Cell trialCell;
  //~ private int rdir;
  //~ private int cdir;
  //~ private int rlim;
  //~ private int clim;
  //~ private int turn;
  //~ private int maxTurns;
  //~ private int counter=0;
  //~ private int maxvalue=999999;
  //~ private boolean checksolution;
  //~ private boolean testing;
  //~ private boolean debug;
  //~ private boolean testColumn;
  //~ private int testIdx;
  //~ private ResourceBundle rb;

  //~ static int GUESSESBEFOREASK=10000;


  //~ public Solver(boolean testing,
                //~ boolean debug,
                //~ boolean testColumn,
                //~ int testIdx,
                //~ Controller control,
                //~ ResourceBundle rb){
    //~ this.control=control;
    //~ this.rb=rb;
    //~ //For development purposes only
    //~ this.testing=testing;
    //~ this.debug=debug;
    //~ this.testColumn=testColumn;
    //~ this.testIdx=testIdx;
  //~ }

  //~ public void setDimensions(int r, int c) {
    //~ rows=r; cols=c; regionCount=r+c;
    //~ grid=new My2DCellArray(r, c);
    //~ solution=new My2DCellArray(r,c);
    //~ regions=new Region[regionCount];
    //~ for (int i=0;i<regionCount;i++) regions[i]=new Region(grid);
  //~ }

  //~ public boolean initialize(String[] rowclues, String[] colclues, My2DCellArray startgrid, My2DCellArray solutiongrid){
    //~ if (rowclues.length!=rows || colclues.length!=cols) {
      //~ out.println("row/col size mismatch\n");
      //~ return false;
    //~ }
    //~ checksolution=false;
    //~ if (solutiongrid!=null) {
      //~ checksolution=true;
      //~ solution.copyFrom(solutiongrid);
    //~ }
    //~ if (startgrid!=null) grid.copyFrom(startgrid);
    //~ else grid.setAll(Resource.CELLSTATE_UNKNOWN);
    //~ for (int r=0; r<rows; r++)regions[r].initialize(r, false,cols,rowclues[r]);
    //~ for (int c=0; c<cols; c++)regions[c+rows].initialize(c,true,rows,colclues[c]);
    //~ return valid();
  //~ }

  //~ public boolean valid(){
    //~ for (Region r : regions)  {
      //~ if (r.inError) return false;
    //~ }
    //~ int rowTotal=0, colTotal=0;
    //~ for (int r=0;r<rows;r++)rowTotal+=regions[r].blockTotal;
    //~ for (int c=0;c<cols;c++)colTotal+=regions[rows+c].blockTotal;
    //~ return rowTotal==colTotal;
  //~ }

  //~ public int solveIt(boolean debug, int maxGuesswork, boolean stepwise, boolean uniqueOnly){
    //~ int simpleresult=simplesolver(debug,true, checksolution, stepwise); //debug,log errors, check solution, step through solution one pass at a time
    //~ if (simpleresult==0 && maxGuesswork>0){
        //~ int[] gridstore= new int[rows*cols];
        //~ return advancedsolver(gridstore, debug, maxGuesswork, uniqueOnly);
    //~ }
    //~ if (rows==1) out.println(regions[0].toString());  //used for debugging
    //~ return simpleresult;
  //~ }

  //~ public boolean getHint(){
    //~ //Solver must be initialised with current state of puzzle before calling.

    //~ int   pass=1;
    //~ while (pass<=30){
      //~ //cycle through regions until one of them is changed then return
      //~ //that region index.
      //~ for (int i=0; i<regionCount; i++){
        //~ if (regions[i].isCompleted) continue;
        //~ if (regions[i].solve(false,true)) {//run solve algorithm in hint mode
          //~ control.updateWorkingGridFromSolver();
          //~ return true;
        //~ }
        //~ if (regions[i].inError){
          //~ Utils.showWarningDialog(rb.getString("A logical error has already been made - cannot hint"));
          //~ return false;
        //~ }
      //~ }
      //~ pass++;
    //~ }
    //~ if (pass>30){
      //~ if (solved()) Utils.showInfoDialog(rb.getString("Already solved"));
      //~ else Utils.showInfoDialog(rb.getString("Cannot find hint"));
    //~ }
    //~ return false;
  //~ }

  //~ private int simplesolver(boolean debug, boolean logerror, boolean checksolution, boolean stepwise){
    //~ boolean changed=true;
    //~ int pass=1, start=regionCount-1;
    //~ while (changed && pass<1000){
      //~ //keep cycling through regions while at least one of them is changing
      //~ changed=false;
      //~ for (Region r : regions){
        //~ if (r.isCompleted) continue;
        //~ if (r.solve(debug,false))changed=true; //no hinting
        //~ if (r.inError) {
          //~ if (debug) out.println("::"+r.message);
          //~ return -1;
        //~ }
        //~ if(checksolution && differsFromSolution(r)) {out.println(r.toString()); return -1;}
        //~ if(debug) out.println(r.toString());
      //~ }
      //~ if(stepwise) break;
      //~ pass++;
    //~ }
    //~ if (solved())return pass;
    //~ return 0;
  //~ }

  //~ public boolean solved(){
    //~ for (Region r : regions){
        //~ //out.println("Region "+r.index+" completed is "+r.isCompleted);
      //~ if (!r.isCompleted) return false;
    //~ }
    //~ return true;
  //~ }


  //~ private boolean differsFromSolution(Region r){
    //~ //use for debugging
    //~ boolean isColumn=r.isColumn;
    //~ int index=r.index;
    //~ int nCells=r.nCells;
    //~ int solutionState, regionState;
    //~ for(int i=0;i<nCells;i++){
      //~ regionState=r.status[i];
      //~ if(regionState==Resource.CELLSTATE_UNKNOWN) continue;
      //~ solutionState=(solution.getCell(isColumn ? i : index, isColumn ? index : i)).state;
      //~ if(solutionState==Resource.CELLSTATE_EMPTY){
        //~ if(regionState==Resource.CELLSTATE_EMPTY) continue;
      //~ }
      //~ else {//solutionState is FILLED
        //~ if (regionState!=Resource.CELLSTATE_EMPTY) continue;
      //~ }
      //~ return true;
    //~ }
    //~ return false;
  //~ }
  //~ private int advancedsolver(int[] gridstore, boolean debug, int maxGuesswork, boolean uniqueOnly){
    //~ // single cell guesses, depth 1 (no recursion)
    //~ // make a guess in each unknown cell in turn
    //~ // if leads to contradiction mark opposite to guess,
    //~ // continue simple solve, if still no solution start again.
    //~ // if does not lead to solution leave unknown and choose another cell
    //~ //out.println("Using advanced solver");
    //~ int simpleresult=0;
    //~ int wraps=0;
    //~ int guesses=0;
    //~ boolean changed=false;
    //~ int countChanged=0;
    //~ int initialmaxTurns=3; //stay near edges until no more changes
    //~ int initialcellstate=Resource.CELLSTATE_FILLED;

    //~ rdir=0; cdir=1; rlim=rows; clim=cols;
    //~ turn=0; maxTurns=initialmaxTurns; guesses=0;
    //~ trialCell= new Cell(0,-1,initialcellstate);

    //~ this.saveposition(gridstore);
    //~ while (true){
      //~ trialCell=makeguess(trialCell); guesses++;
      //~ if (trialCell.col==-1){ //run out of guesses
        //~ if (changed){
          //~ if(countChanged>maxGuesswork) return 0;
        //~ }
        //~ else if (maxTurns==initialmaxTurns){
          //~ maxTurns=(Math.min(rows,cols))/2+2; //ensure full coverage
        //~ }
        //~ else if(trialCell.state==initialcellstate){
          //~ trialCell=trialCell.invert(); //start making opposite guesses
          //~ maxTurns=initialmaxTurns; wraps=0;
        //~ }
        //~ else break; //cant make progress
        //~ rdir=0; cdir=1; rlim=rows; clim=cols; turn=0;
        //~ changed=false;
        //~ wraps++;
        //~ continue;
      //~ }
      //~ grid.setDataFromCell(trialCell);
      //~ simpleresult=simplesolver(false,false,false,false); //only debug advanced part, ignore errors
      //~ if (simpleresult>0)break; // solution found
      //~ //if (simpleresult>0 && uniqueOnly) {countChanged++; simpleresult=0; break;}//solution found (but not necessarily unique so reject it)
      //~ loadposition(gridstore); //back track
      //~ if (simpleresult<0){ //contradiction -  insert opposite guess
        //~ grid.setDataFromCell(trialCell.invert()); //mark opposite to guess
        //~ changed=true; countChanged++;//worth trying another cycle
        //~ simpleresult=simplesolver(false,false,false,false);//can we solve now?
        //~ if (simpleresult==0){//no we cant
          //~ this.saveposition(gridstore); //update grid store
          //~ continue; //go back to start
        //~ }
        //~ else if (simpleresult>0)break; // solution found
        //~ else return -1; //starting point was invalid
      //~ }
      //~ else  continue; //guess again
    //~ }
    //~ //return vague measure of difficulty
    //~ if (simpleresult>0) return simpleresult+countChanged*20;
    //~ return 999999;
  //~ }

  //~ private void saveposition(int[] gs){
    //~ //store grid in linearised form.
    //~ for(int r=0; r<rows; r++){
     //~ for(int c=0; c<cols; c++){
        //~ gs[r*cols+c]=grid.getDataFromRC(r,c);
    //~ } }
    //~ for (int i=0; i<regionCount; i++) regions[i].savestate();
  //~ }

  //~ private void loadposition(int[] gs){
    //~ for(int r=0; r<rows; r++){
      //~ for(int c=0; c<cols; c++){
        //~ grid.setDataFromRC(r,c, gs[r*cols+c]);
    //~ } }
    //~ for (int i=0; i<regionCount; i++) regions[i].restorestate();
  //~ }

  //~ private Cell makeguess(Cell cell){
    //~ //Scan in spiral pattern from edges.  Critical cells most likely in this region
    //~ int r=cell.row;
    //~ int c=cell.col;
    //~ while (true){
      //~ r+=rdir; c+=cdir; //only one changes at any one time
      //~ if (cdir==1 && c>=clim) {c--;cdir=0;rdir=1;r++;} //across top - rh edge reached
      //~ else if (rdir==1 && r>=rlim) {r--;rdir=0;cdir=-1;c--;} //down rh side - bottom reached
      //~ else if (cdir==-1 && c<turn) {c++; cdir=0;rdir=-1;r--;} //back across bottom lh edge reached
      //~ else if (rdir==-1 && r<=turn) {r++;turn++;rlim--;clim--;rdir=0;cdir=1;} //up lh side - top edge reached
      //~ if (turn>maxTurns) {//stay near edge until no more changes
        //~ cell.row=0;
        //~ cell.col=-1;
        //~ break;
      //~ }
      //~ if (grid.getDataFromRC(r,c)==Resource.CELLSTATE_UNKNOWN){
        //~ cell.row=r; cell.col=c;
        //~ break;
    //~ } }
    //~ return cell;
  //~ }

  //~ public Cell getCell(int r, int c){
        //~ return grid.getCell(r,c);
    //~ }

//~ }
}
