//
//  MeshExporter.cpp
//  FbxAwdExporter
//
//  Created by Pierre Lepers on 05/11/2014.
//
//

#include "MeshExporter.h"
#include "GeomExporter.h"
#include "utils.h"



bool MeshExporter::isHandleObject( FbxObject *pObj ){
    if( pObj->Is<FbxNode>() ){
        FbxNode * lNode = (FbxNode*) pObj;
        FbxNodeAttribute::EType nType = (lNode->GetNodeAttribute()->GetAttributeType());
        return nType == FbxNodeAttribute::eMesh;
    }
    return false;
}

void MeshExporter::doExport(FbxObject* pObj){
    
    FbxNode *pNode = (FbxNode*) pObj;
    
    
    // export Geometry
    
    AWDTriGeom *geomBlock = NULL;
    
    FbxMesh *lMesh = pNode->GetMesh();
    
    if( lMesh )
    {
        GeomExporter* gExporter = new GeomExporter();
        gExporter->setup( mContext, mExporters );
        gExporter->doExport( lMesh );
        gExporter->release();
        
        // call GetMesh again after geom export since
        // geom exporter can replace the actual Mesh attribute
        // (Triangulation)
        lMesh = pNode->GetMesh();
        
        geomBlock = (AWDTriGeom*) mContext->GetBlocksMap()->Get( lMesh );
        
        if( geomBlock == NULL )
        {
            FBXSDK_printf( "WARN : geom not found/exported, mesh exported without geometry! \n" );
        }

    }
    
    
    // export MeshInstance
    //
    const char *name = pNode->GetName();
    AWDMeshInst* awdMesh = new AWDMeshInst( name, static_cast<unsigned short>(strlen(name)), geomBlock );
    
    AwdUtils::CopyNodeTransform( pNode, awdMesh );
    
    AWDSceneBlock *parent = (AWDSceneBlock*) mContext->GetBlocksMap()->Get( pNode->GetParent() );
    awdMesh->set_parent( parent );
    
    
    
    // retreive materials
    // 
    // materials should have already been exported
    // by GeomExporter. Just retreive them from cache.
    
    AWDBlockList *materialList = new AWDBlockList();
    
    AWDSubGeom *sub;
    
    sub = geomBlock->get_first_sub();
    while (sub) {
        if( sub->get_materials()->get_num_blocks() > 0 )
        {
            AWDMaterial *mat = (AWDMaterial*)sub->get_materials()->first_block->block;
            materialList->append( mat );
            awdMesh->add_material( mat );
        } else {
            // TODO : here we should add a default material or whatever to fill the hole
            // and keep a correct material mapping
            FBXSDK_printf( "WARN : subgeom without material found! stream 0 len : %i \n", sub->get_stream_at(0)->get_length() );
        }
        sub = sub->next;
    }
    
    
    awdMesh->set_defaultMat(materialList->getByIndex(0));
    awdMesh->set_pre_materials( materialList );
    
    // add to awd
    //
    mContext->add_scene_block( awdMesh, pNode );
    
}