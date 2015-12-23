function matchRanking( obj )
%MATCHRANKING Summary of this function goes here
%   Detailed explanation goes here

debug = true;

residualIdArray = [];

% Set the rank of known variables to 0
id=obj.getIdByProperty('isKnown');
for i=id
    obj.setRank(i,0);
end

k=1; % Set starting rank
numMatchedVars = length(id);
numMatchedEqs = 0;

unmatchedObjIds = obj.getIdByProperty('rank',inf);
while ~isempty(unmatchedObjIds) % While there are unmatched variables or constraints
    noChange = true;
    fprintf('Rank %d: Matched Variables:%d/%d, Constraints:%d/%d\n', k,numMatchedVars,obj.numVars,numMatchedEqs,obj.numEqs );
    
    % For each unmatched constraint
    for eqId=obj.getEqIdByProperty('rank',inf)
        eqIndex = find(obj.equationIdArray==eqId);
        if debug fprintf('Examining equation %s: ',obj.equationAliasArray{eqIndex}); end
        
        % Find its unmatched variables 
        varId = obj.equationArray(eqIndex).getIdByProperty('rank',inf);
        if debug fprintf('it has %d unmatched variable(s)',length(varId)); end
        
        % Does this equation have only one unmatched variable?
        booltest1 = length(varId) == 1;
        
        % If yes, can it be solved for?
        if booltest1
            varIndex = find(obj.equationArray(eqIndex).variableIdArray==varId);
            % ... and it can be solved for (TODO: make solvability test
            % more general)
            booltest2 = ~obj.equationArray(eqIndex).variableArray(varIndex).isNonSolvable;
        end
        
        % Furthermore, can it be calculated by variables known in the
        % previous rank?
        booltest3 = false;
        if booltest1 && booltest2
            booltest3 = true;
            varIndices = 1:obj.equationArray(eqIndex).numVars;
            otherVarIndices = find(varIndices~=varIndex);
            if debug fprintf(' (uses: '); end
            for i=otherVarIndices
                if debug fprintf('%s/%d, ',obj.equationArray(eqIndex).variableArray(i).alias,obj.equationArray(eqIndex).variableArray(i).rank); end
                if obj.equationArray(eqIndex).variableArray(i).rank == k
                    booltest3=false;
                end
            end
            if debug fprintf(') '); end
        end
            
        if booltest1
            if booltest2
                noChange = false;
                if booltest3
                    if debug fprintf(', which can be solved for now.\n'); end
                    % Match this constraint
                    obj.setRank(eqId,k);
                    numMatchedEqs = numMatchedEqs + 1;
                    obj.equationArray(eqIndex).isMatched = true;
                    % ... and the variable
                    obj.equationArray(eqIndex).variableArray(varIndex).isMatched = true;
                    obj.setRank(varId,k);
                    obj.setKnown(varId);
                    numMatchedVars = numMatchedVars + 1;
                else
                    if debug fprintf(', but it will be available in the next rank.\n'); end
                end
            else
                if debug fprintf(', but it cannot be solved for\n'); end
            end
        else
            if debug fprintf('.\n'); end
        end
        
    end
    
    % Look for residual generators
    % For each unmatched equation
    for eqId=obj.getEqIdByProperty('rank',inf)
        eqIndex = find(obj.equationIdArray==eqId);
        % Find its unmatched variables
        varId = obj.equationArray(eqIndex).getIdByProperty('rank',inf);
        
        % Does this equation have no unmatched variables?
        booltest1 = isempty(varId);
        
        % Furthermore, can it be calculated by variables known in the
        % previous rank?
        booltest2 = false;
        if booltest1
            booltest2 = true;
            varIndices = 1:obj.equationArray(eqIndex).numVars;
            for i=varIndices
                if obj.equationArray(eqIndex).variableArray(i).rank == k
                    booltest2=false;
                end
            end
        end        
        
        if booltest1 && booltest2 % Find those with all their variables matched
            if debug fprintf('Assigning a residual to equation %s\n',obj.equationAliasArray{eqIndex}); end
            obj.setRank(eqId,k); % assign this constraint as matched in this rank
            obj.equationArray(eqIndex).isMatched = true;
            numMatchedEqs = numMatchedEqs + 1;
            residualIdArray(end+1) = eqId; % And assign a residual generator onto them
            obj.equationArray(eqIndex).isResGenerator = true;
        end
        
    end

    if noChange % Did anything new happen in this loop?
        disp(sprintf('Nothing new in rank %d',k));
        break;
    end
    
    k = k+1;
    unmatchedObjIds = obj.getIdByProperty('rank',inf);
    
end

%% Check matching characteristics

matchedEqs = 0;
for i=1:obj.numEqs
    if obj.equationArray(i).rank ~= inf
        matchedEqs = matchedEqs + 1;
    end
end
matchedVars = 0;
for i=1:obj.numVars
    if obj.variableArray(i).rank ~= inf
        matchedVars = matchedVars + 1;
    end
end
numResiduals = length(residualIdArray);

fprintf('Matching results:\n');
fprintf('%d/%d variables matched\n',matchedVars,obj.numVars);
fprintf('%d residuals generated\n',numResiduals);
fprintf('%d equations used\n',matchedEqs);


end
