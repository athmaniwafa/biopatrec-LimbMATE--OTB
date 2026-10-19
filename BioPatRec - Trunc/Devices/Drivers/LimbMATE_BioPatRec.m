classdef LimbMATE_BioPatRec < LimbMATE
    % LimbMATE_BioPatRec
    % Thin subclass of LimbMATE used by BioPatRec's recording session.
    % Inherits all properties and methods from LimbMATE. Adds nothing
    % new; exists only so BioPatRec has a stable class name to instantiate.

    methods
        function obj = LimbMATE_BioPatRec()
            obj@LimbMATE();
            obj.graphical_information = struct('enable_graph', 0);
        end
    end
end