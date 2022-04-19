using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShaderUtil
{
    //获得用于基于射线方式从屏幕空间反推世界坐标的四个分角向量
    public static Matrix4x4 GetViewPortRay(Camera currentCamera)
    {
        Transform transform = currentCamera.transform;
        var aspect = currentCamera.aspect;
        var far = currentCamera.farClipPlane;
        var right = transform.right;
        var up = transform.up;
        var forward = transform.forward;
        var halfFovTan = Mathf.Tan(currentCamera.fieldOfView * 0.5f * Mathf.Deg2Rad);

        //计算相机在远裁剪面处的xyz三方向向量
        var rightVec = right * far * halfFovTan * aspect;
        var upVec = up * far * halfFovTan;
        var forwardVec = forward * far;

        //构建四个角的方向向量
        var topLeft = (forwardVec - rightVec + upVec);
        var topRight = (forwardVec + rightVec + upVec);
        var bottomLeft = (forwardVec - rightVec - upVec);
        var bottomRight = (forwardVec + rightVec - upVec);

        var viewPortRay = Matrix4x4.identity;
        viewPortRay.SetRow(0, topLeft);
        viewPortRay.SetRow(1, topRight);
        viewPortRay.SetRow(2, bottomLeft);
        viewPortRay.SetRow(3, bottomRight);

        return viewPortRay;

        /*
        //用texcoord区分四个角
		int index = 0;
		if (v.texcoord.x < 0.5 && v.texcoord.y > 0.5)
			index = 0;
		else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5)
			index = 1;
		else if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5)
			index = 2;
		else
			index = 3;
		
		o.rayDir = _ViewPortRay[index];

        */

    }
}
