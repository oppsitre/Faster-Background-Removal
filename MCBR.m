function [res_1, res_2] = MCBR(cha1, cha2)
    cha1_nor = normalize(cha1);
    cha2_nor = normalize(cha2);
    sub_cha1 = cha1_nor - cha2_nor;
    sub_cha2 = cha2_nor - cha1_nor;
    [sx,sy,sz] = size(cha1_nor);
    for i = 1:sz
        cha1_nor(:,:,i) = estimate_scatter(sub_cha1(:,:,i),cha1(:,:,i));
        cha2_nor(:,:,i) = estimate_scatter(sub_cha2(:,:,i),cha2(:,:,i));
    end
    res_1 = enhance(cha1 - cha1_nor);
    res_2 = enhance(cha2 - cha2_nor);
end

function [img] = normalize(img)
    [sx,sy,sz] = size(img);
    for i = 1:sz
        min_val = min(min(img(:,:,i)));
        max_val = max(max(img(:,:,i)));
        img(:,:,i) = (img(:,:,i) - min_val) / (max_val - min_val);
    end
end

function [Z] = estimate_scatter(sub,ori)
    %B = sub;
    ws = 5;
    [sx,sy] = size(sub);
    x = zeros(sx*sy,1);
    y = zeros(sx*sy,1);
    z = zeros(sx*sy,1);
    bnum = 1;
    for i = 1:ws:sx
        for j = 1:ws:sy
            A = sub(i:min(sx,i+ws-1),j:min(sy,j+ws-1));
            min_val = min(min(A));
            if min_val <= 0 && ori(i,j) ~= 0
                [xx, yy] = find(A == min_val);
                x(bnum) = xx(1) + i - 1;
                y(bnum) = yy(1) + j - 1;
                z(bnum) = ori(x(bnum),y(bnum));
                bnum = bnum + 1;
            end
        end
    end
    x = double(x(1:bnum));
    y = double(y(1:bnum));
    z = double(z(1:bnum));
    F = scatteredInterpolant(x,y,z);
    [X,Y] = meshgrid(1:sx,1:sy);
    Z = int16(F(X,Y));
end

function [Z] = estimate_linear(sub,ori)
    %B = sub;
    ws = 7;
    [sx,sy] = size(sub);
    wnx = floor((sx-1)/ws)+1;
    wny = floor((sy-1)/ws)+1;
    B = zeros(wnx,wny) - 1;
    for i = 1:ws:sx
        for j = 1:ws:sy
            A = sub(i:min(sx,i+ws-1),j:min(sy,j+ws-1));
            min_val = min(min(A));
            if min_val <= 0 && ori(i,j) ~= 0
                [xx, yy] = find(A == min_val);
                B(floor((i-1)/ws)+1,floor((j-1)/ws)+1) = ori(xx(1) + i - 1, yy(1) + j - 1);
            end
        end
    end
    for i = 1:wnx
        for j = 1:wny
            if B(i,j) == -1
                r = 1;
                while(1)
                    tarray = B(max(1,(i-r)):min(wny,(i+r)),max(1,(j-r)):min(wny,(j+r)));
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
    [tx,ty] = meshgrid(1:ws:sx,1:ws:sy);
    [X,Y] = meshgrid(1:sx,1:sy);
    Z = interp2(tx,ty,B,X,Y);
end

function [res] = enhance(I)
    res=double(I)*255.0/double(quantile(I(:),0.995));
    res=uint8(res);
end
