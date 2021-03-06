classdef Plotter < matlab.mixin.Copyable
    %PLOTTER Coordinator class for graph plotting utilities
    %   Detailed explanation goes here
    
    properties
        gi = GraphInterface.empty;
    end
    
    methods
        function obj = Plotter(gi)
            % Class constructor
            obj.gi = gi;
        end
        function fh = plotDM(this)
            % PlotDM(SM) Plots a Dulmage-Mendelsohn decomposition
            % Uses Linkopping University Fault Diagnosis library
            liuSM = createLiusm(this.gi);
            %             liuSM.Lint();
            fh = figure();
            liuSM.PlotDM('eqclass',true,'fault',true);
        end
        function plotDot(this,graphName,compile)
            % Generate .dot code from this graph
            
            debug = true;
            
            if nargin<2
                graphName = 'myGraph';
            end
            if nargin<3
                compile = true;
            end
            
            folderName = sprintf('GraphPool/%s/graphs',this.gi.graph.name);
            if ~exist(folderName,'dir')
                mkdir(folderName);
            end
            
            dotName = sprintf('%s.dot',graphName);
            imageName = sprintf('%s.ps',graphName);
            dotFilePath = sprintf('GraphPool/%s/graphs/%s',this.gi.graph.name,dotName);
            imageFilePath = sprintf('GraphPool/%s/graphs/%s',this.gi.graph.name,imageName);
            
            fileID = fopen(dotFilePath,'w');
            % Write header
            fprintf(fileID,'digraph G {\n');
            fprintf(fileID,'rankdir = LR;\n');
            fprintf(fileID,'size ="8.5"\n');
            nodeDef = '';
            edgeDef = '';
            
            for i=1:this.gi.graph.numEqs
                color = 'white';
                frameColor = 'black';
                if this.gi.graph.equations(i).isMatched
                    color = 'lightskyblue';
                end
                if this.gi.graph.equations(i).isFaultable
                    frameColor = 'red';
                end
                nodeDef = [nodeDef sprintf('node [shape = box, color = %s, fillcolor = %s, style = filled, label="%s\n%d"]; %s;\n'...
                    ,frameColor,color,this.gi.reg.equAliasArray{i},this.gi.reg.equIdArray(i),this.gi.reg.equAliasArray{i})];
            end
            
            for i=1:this.gi.graph.numVars
                shape = 'circle';
                color = 'white';
                frameColor = 'black';
                if this.gi.graph.variables(i).isKnown
                    % No operation
                end
                if this.gi.graph.variables(i).isMeasured
                    color = 'yellow';
                end
                if this.gi.graph.variables(i).isInput
                    color = 'green';
                    shape = 'doublecircle';
                end
                if this.gi.graph.variables(i).isFault
                    color = 'red';
                    shape = 'doublecircle';
                end
                if this.gi.graph.variables(i).isParameter
                    color = 'orange';
                end
                if this.gi.graph.variables(i).isOutput
                    shape = 'Mcircle';
                end
                if this.gi.graph.variables(i).isMatched
                    color = 'lightskyblue';
                end
                if this.gi.graph.variables(i).isDisturbance
                    color = 'tomato';
                    shape = 'doublecircle';
                end
                nodeDef = [nodeDef sprintf('node [shape = %s, color = %s, fillcolor = %s, style = filled, label="%s\n%d"]; %s;\n'...
                    ,shape,frameColor,color,this.gi.reg.varAliasArray{i},this.gi.reg.varIdArray(i),this.gi.reg.varAliasArray{i})];
            end
            
            E = this.gi.getEdgeList();
            for i=1:size(E,1)
                penwidth = 1;
                id1 = E(i,1);
                id2 = E(i,2);
                if this.gi.isVariable(id1) % V2E edge
                    varIndex = this.gi.getIndexById(id1);
                    equIndex = this.gi.getIndexById(id2);
                    edgeDef = [edgeDef sprintf('%s -> %s [penwidth = %g, label = "%d"];\n',this.gi.reg.varAliasArray{varIndex},this.gi.graph.equations(equIndex).alias,penwidth, this.gi.getEdgeIdByVertices(id2,id1))];
                else% E2V edge
                    equIndex = this.gi.getIndexById(id1);
                    varIndex = this.gi.getIndexById(id2);
                    if this.gi.isMatched(id2)
                        penwidth = 1.5;
                    end
                    edgeDef = [edgeDef sprintf('%s -> %s [penwidth = %g, label = "%d", color = red4 ];\n',this.gi.graph.equations(equIndex).alias,this.gi.reg.varAliasArray{varIndex},penwidth, this.gi.getEdgeIdByVertices(id1,id2))];
                end
            end
            
            fprintf(fileID,nodeDef);
            fprintf(fileID,edgeDef);
            
            % Close file
            fprintf(fileID,'}\n');
            fclose(fileID);
            
            % Run 'dot -Tps mygraph.dot -o mygraph.ps' in the command line
            if compile
                s = system(sprintf('dot -Tps %s -o %s',dotFilePath, imageFilePath));
                if s
                    warning('Failed to run "dot" command to generate graph image');
                end
            end
            
        end
        
    end
    
end

