function [metData] = metanetxMapper(metInfo, varargin)
% This function converts metabolite names into MetaNetX metabolite IDs
% using API
%
% USAGE:
%
%    [metData] = metanetxMapper(metInfo, inputStyle, outputStyle)
%
% INPUTS:
%    name:     string name of the metabolite (Common names, VMH names, CHEBI ids,
%    swiss lipids id, HMDB ids, and lipidmaps are supported)
%
%    inputStyle: For inputs in the format of names use 'name' and for
%    different IDs you can use 'chebi', 'vmh', 'hmdb', 'swisslipids' or
%    'metanetx'
%
% OPTIONAL INPUT:
%    outputStyle: same as the input, choose an output option between
%    'name', 'vmh', 'chebi', 'hmdb', 'swisslipids', and 'metanetx'
%
% OUTPUT:
%    metData: Name of ID for metabolite of interest
%
% EXAMPLE:
%
%    >>  metanetxID = metanetxMapper('10dacb')
%        metanetxID =
%       'MNXM1702'
%    >>  metanetxID = getMetanetxID('10dacb', 'name')
%        metanetxID =
%       '10-deacetylbaccatin III'
%
% NOTE:
%    In the case of more than one matches for the metabolite, this
%    functions returns the first match
%    This function adds "+" sign at the begining of the metabolites name to
%    find the exact match in MetaNetX website
%
% .. Author:
%           - Farid Zare, 7/12/2024
%

% Change the format to char if it is a cell or string
if ~ischar(metInfo)
    metInfo = char(metInfo);
end

% Input is an ID by default
nameFlag = 0;
if nargin > 1 && ~isempty(metInfo)
    % Assuming varargin{1} is the second input argument
    switch lower(varargin{1})
        case 'name'
            nameFlag = 1;
        case 'vmh'
            metInfo = ['vmhM:', metInfo];
        case 'chebi'
            metInfo = ['CHEBI:', metInfo];
        otherwise
            error('Unrecognized input type of data. Input data type should be either "name" or "id"');
    end
end

% Inorder to get the exact ID, "+" is added to the beggining of the name
% metabolite
if ~isempty(metInfo)
    if metInfo(1) ~= '+'
        metInfo = strcat('+', metInfo);
    end
end

% For names its better to use MetaNetX search and for IDs we use id-mapper
% feature of MetaNetX website
if nameFlag
    % For names its better to use MetaNetX search
    url = 'https://beta.metanetx.org/cgi-bin/mnxweb/search';
    params = {'format', 'json', 'db', 'chem', 'query', metInfo};
else
    % For IDs we use id-mapper feature of MetaNetX
    url = 'https://beta.metanetx.org/cgi-bin/mnxweb/id-mapper';
    params = {'query_index', 'chem', 'output_format', 'JSON', 'query_list', metInfo};
end

% Define output as a struct
metData = struct('name', "", 'metanetx', "", 'vmh', "", 'chebi', "", 'hmdb', "", 'kegg', "", 'bigg', "", 'swisslipids', "");

% Make the request using webread and respond an empty response to empty
% names
if ~isempty(metInfo)
    response = webread(url, params{:});
else
    response = '';
end

if nameFlag
    if ~isempty(response) 

        % For cases using MetaNetX name search in the cases of more than 1 result
        % the first result is counted
        if numel(response) > 1
            response = response{1};
        end
        % Get the second respond using the retrieved metanetx id
        metInfo = response.desc;
        % For IDs we use id-mapper feature of MetaNetX
        url = 'https://beta.metanetx.org/cgi-bin/mnxweb/id-mapper';
        params = {'query_index', 'chem', 'output_format', 'JSON', 'query_list', metInfo};
        % Make the request using webread
        response = webread(url, params{:});

    end
end

if ~isempty(response) 

    % Getting the subfield in the struct field
    fields = fieldnames(response);
    response = response.(fields{1});

    if ~isempty(fieldnames(response))

        % Assign metanetx and name
        metData.metanetx = string(response.mnx_id);
        metData.name = string(response.name);

        ref = response.xrefs;

        % Assign Chebi ID
        chebiID = find(contains(lower(ref), 'chebi'));
        if ~isempty(chebiID)
            % First ID is the real ID others might be similar mets
            chebi = ref(chebiID(1));
            chebi = string(chebi);
            chebi = strsplit(chebi, ':');
            metData.chebi = string(chebi{2});
        end

        % Assign hmdb ID
        hmdbID = find(contains(lower(ref), 'hmdb'));
        if ~isempty(hmdbID)
            % First ID is the real ID others might be similar mets
            hmdb = ref(hmdbID(1));
            hmdb = string(hmdb);
            hmdb = strsplit(hmdb, ':');
            metData.hmdb = string(hmdb{2});
        end

        % Assign vmh ID
        vmhID = find(contains(lower(ref), 'vmhm'));
        if ~isempty(vmhID)
            % First ID is the real ID others might be similar mets
            vmh = ref(vmhID(1));
            vmh = string(vmh);
            vmh = strsplit(vmh, ':');
            metData.vmh = string(vmh{2});
        end

        % Assign swisslipids ID
        slmID = find(contains(lower(ref), 'slm'));
        if ~isempty(slmID)
            % First ID is the real ID others might be similar mets
            slm = ref(slmID(1));
            slm = string(slm);
            metData.swisslipids = slm;
        end

        % Assign KEGG ID
        keggID = find(contains(lower(ref), 'kegg.compound'));
        if ~isempty(keggID)
            % First ID is the real ID others might be similar mets
            kegg = ref(keggID(1));
            kegg = string(kegg);
            kegg = strsplit(kegg, ':');
            metData.kegg = string(kegg{2});
        end

        % Assign BIGG ID
        biggID = find(contains(lower(ref), 'bigg.metabolite'));
        if ~isempty(biggID)
            % First ID is the real ID others might be similar mets
            bigg = ref(biggID(1));
            bigg = string(bigg);
            bigg = strsplit(bigg, ':');
            metData.bigg = string(bigg{2});
        end
    end
end
end
