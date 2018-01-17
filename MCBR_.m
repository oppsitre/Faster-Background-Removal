function [res_1, res_2] = MCBR_(cha1, cha2, ws_1, ws_2, ws_3, th)
    ws_1 = 128; ws_2 = 256;
    cha1_nor = normalize(cha1, ws_1);
    cha2_nor = normalize(cha2, ws_2);
    sub_cha1 = cha1_nor - cha2_nor;
    sub_cha2 = cha2_nor - cha1_nor;
    figure; imshow3D(uint8(sub_cha1*255));
    figure; imshow3D(uint8(sub_cha2*255));
%     sub_cha1 = cha1 - cha2;
%     sub_cha2 = cha2 - cha1;
    [sx,sy,sz] = size(cha1);
    B_1 = cha1; B_2 = cha2;
    for i = 1:sz
        B_1(:,:,i) = Estimate_Background_Robust(sub_cha1(:,:,i), cha1(:,:,i), ws_3, th);
        B_2(:,:,i) = Estimate_Background_Robust(sub_cha2(:,:,i), cha2(:,:,i), ws_3, th);
    end
    figure; imshow3D(uint8(B_1));
    figure; imshow3D(uint8(B_2));
    res_1 = uint8(double(cha1) - B_1);
    res_2 = uint8(double(cha2) - B_2);
%     res_1 = enhance(cha1 - B_1);
%     res_2 = enhance(cha2 - B_2);
end

function [img] = normalize(img, ws)
    img = img / 256;
    [sx,sy,sz] = size(img);
    for k = 1:sz
        for i = 1:ws:sx
            for j = 1:ws:sy
                edx = min(sx, i + ws - 1);
                edy = min(sy, j + ws - 1);
                tmp = img(i:edx, j:edy, k);
                min_val = min(min(img));
                max_val = max(max(img));
%                 max_val = max(max(tmp));
                tmp = min(1, max(0, (tmp - min_val) / (max_val - min_val)));
                img(i:edx, j:edy, k) = tmp;
            end
        end
    end
end

function [Z] = Estimate_Background_Robust(sub, ori, ws_3, th, dis)
    [sx, sy] = size(sub);
    p = zeros(sx*sy, 4, 'double');
    pnum = 0;
    ws = ws_3;
    for i = 1:ws:sx
        for j = 1:ws:sy
            edx = min(sx, i+ws-1);
            edy = min(sy, j+ws-1);
            S = sub(i:edx, j:edy);
            O = ori(i:edx, j:edy);
            id = find(S < th);
            if size(id) < ws_3*ws_3
                continue;
            end
            pnum = pnum + 1;
            p(pnum,:) = [i + floor(ws / 2) j + floor(ws / 2) mean(S(id)) median(O(id))];
        end
    end
    pnum
    p = p(1:pnum, :);
    p = sortrows(p, 3);
    ws = 16;
    dis = floor(ws/2);
    B = zeros(sx, sy, 'double') - 1;
    b = zeros(ceil(sx/ws + 1)* ceil(sy/ws + 1), 3);
    bnum = 0;
    for i = 1:pnum
        tx = p(i, 1);
        ty = p(i, 2);
        lx = max(1, tx - dis); rx = min(sx, tx + dis);
        ly = max(1, ty - dis); ry = min(sy, ty + dis);
        if ~isempty(find(B(lx:rx, ly:ry) ~= -1))
            continue;
        end
        bnum = bnum + 1;
        O = ori(lx:rx, ly:ry);
        b(bnum, :) = [tx ty min(prctile(O(:), 20), p(i,4))];
        B(tx, ty) = p(i,4);
    end
    bnum
    b = b(1:bnum,:);
    Z = interpolation_linear(b(:,1),b(:,2),b(:,3),sx,sy,ws);
end


function [Z] = interpolation_linear(x,y,z,sx,sy,ws)
    wnx = ceil((sx-1)/ws);
    wny = ceil((sy-1)/ws);
    B = zeros(wnx+2, wny+2, 'double') - 1;
    for i = 1:size(x,1)
        a = ceil((x(i)-1)/ws)+1;
        b = ceil((y(i)-1)/ws)+1;
        if B(a, b) == -1
            B(a, b) = z(i);
        else
            B(a, b) = min(B(a,b),z(i));
        end
    end
    for i = 1:(wnx+2)
        for j = 1:(wny+2)
            if B(i,j) == -1
                r = 1;
                while(1)
                    tarray = B(max(1,(i-r)):min(wny+2,(i+r)),max(1,(j-r)):min(wny+2,(j+r)));
                    [idx,idy] = find(tarray > 0);
                    if ~isempty(idx)
                        tarray = tarray(idx,idy);
                        B(i,j) = median(tarray(:));
                        break;
                    end
                    r = r + 1;
                end
            end
        end
    end
    ws
    [X,Y] = meshgrid(1:(wnx+2)*ws, 1:(wny+2)*ws);
    Xg = (1:ws:(wnx+2)*ws) + ws;
    Yg = (1:ws:(wny+2)*ws) + ws;
    [tx,ty] = meshgrid(Xg, Yg);
    Z = interp2(tx,ty,B,X,Y);
    Z = int16(Z((ws+1):(sx+ws), (ws+1):(sy+ws)));
end

function [res] = enhance(I)
    res=double(I)*255.0/double(quantile(I(:),0.995));
    res=uint8(res);
end