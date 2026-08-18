export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.15"
  }
  public: {
    Tables: {
      admin_bootstrap_state: {
        Row: {
          admin_user_id: string
          bootstrapped_at: string
          bootstrapped_by: string | null
          id: boolean
        }
        Insert: {
          admin_user_id: string
          bootstrapped_at?: string
          bootstrapped_by?: string | null
          id?: boolean
        }
        Update: {
          admin_user_id?: string
          bootstrapped_at?: string
          bootstrapped_by?: string | null
          id?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "admin_bootstrap_state_admin_user_id_fkey"
            columns: ["admin_user_id"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "admin_bootstrap_state_bootstrapped_by_fkey"
            columns: ["bootstrapped_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_roles: {
        Row: {
          code: string
          created_at: string
          id: string
          name_ar: string
          permissions: Json
        }
        Insert: {
          code: string
          created_at?: string
          id?: string
          name_ar: string
          permissions?: Json
        }
        Update: {
          code?: string
          created_at?: string
          id?: string
          name_ar?: string
          permissions?: Json
        }
        Relationships: []
      }
      admin_users: {
        Row: {
          created_at: string
          created_by: string | null
          is_active: boolean
          role_id: string
          scope: Json
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          is_active?: boolean
          role_id: string
          scope?: Json
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          is_active?: boolean
          role_id?: string
          scope?: Json
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "admin_users_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_users_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "admin_roles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_users_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      audit_logs: {
        Row: {
          action: string
          actor_user_id: string | null
          created_at: string
          entity_id: string | null
          entity_type: string
          id: string
          metadata: Json
        }
        Insert: {
          action: string
          actor_user_id?: string | null
          created_at?: string
          entity_id?: string | null
          entity_type: string
          id?: string
          metadata?: Json
        }
        Update: {
          action?: string
          actor_user_id?: string | null
          created_at?: string
          entity_id?: string | null
          entity_type?: string
          id?: string
          metadata?: Json
        }
        Relationships: [
          {
            foreignKeyName: "audit_logs_actor_user_id_fkey"
            columns: ["actor_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      banners: {
        Row: {
          body_ar: string | null
          created_at: string
          cta_label_ar: string | null
          cta_url: string | null
          ends_at: string | null
          id: string
          image_url: string | null
          is_active: boolean
          sort_order: number
          starts_at: string | null
          title_ar: string
          updated_at: string
        }
        Insert: {
          body_ar?: string | null
          created_at?: string
          cta_label_ar?: string | null
          cta_url?: string | null
          ends_at?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean
          sort_order?: number
          starts_at?: string | null
          title_ar: string
          updated_at?: string
        }
        Update: {
          body_ar?: string | null
          created_at?: string
          cta_label_ar?: string | null
          cta_url?: string | null
          ends_at?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean
          sort_order?: number
          starts_at?: string | null
          title_ar?: string
          updated_at?: string
        }
        Relationships: []
      }
      categories: {
        Row: {
          category_kind: string
          created_at: string
          id: string
          is_active: boolean
          name_ar: string
          name_en: string | null
          parent_id: string | null
          slug: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          category_kind?: string
          created_at?: string
          id?: string
          is_active?: boolean
          name_ar: string
          name_en?: string | null
          parent_id?: string | null
          slug: string
          sort_order?: number
          updated_at?: string
        }
        Update: {
          category_kind?: string
          created_at?: string
          id?: string
          is_active?: boolean
          name_ar?: string
          name_en?: string | null
          parent_id?: string | null
          slug?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "categories_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "categories_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "customer_products"
            referencedColumns: ["category_id"]
          },
        ]
      }
      certifications: {
        Row: {
          created_at: string
          description: string | null
          icon_key: string | null
          id: string
          issuer: string | null
          name_ar: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          icon_key?: string | null
          id?: string
          issuer?: string | null
          name_ar: string
        }
        Update: {
          created_at?: string
          description?: string | null
          icon_key?: string | null
          id?: string
          issuer?: string | null
          name_ar?: string
        }
        Relationships: []
      }
      comment_likes: {
        Row: {
          comment_id: string
          created_at: string
          user_id: string
        }
        Insert: {
          comment_id: string
          created_at?: string
          user_id: string
        }
        Update: {
          comment_id?: string
          created_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "comment_likes_comment_id_fkey"
            columns: ["comment_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comment_likes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      comments: {
        Row: {
          author_id: string
          body: string
          created_at: string
          id: string
          parent_comment_id: string | null
          product_id: string | null
          review_id: string | null
          status: string
          updated_at: string
        }
        Insert: {
          author_id: string
          body: string
          created_at?: string
          id?: string
          parent_comment_id?: string | null
          product_id?: string | null
          review_id?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          author_id?: string
          body?: string
          created_at?: string
          id?: string
          parent_comment_id?: string | null
          product_id?: string | null
          review_id?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "comments_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_parent_comment_id_fkey"
            columns: ["parent_comment_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "customer_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "reviews"
            referencedColumns: ["id"]
          },
        ]
      }
      conversation_participants: {
        Row: {
          conversation_id: string
          created_at: string
          user_id: string
        }
        Insert: {
          conversation_id: string
          created_at?: string
          user_id: string
        }
        Update: {
          conversation_id?: string
          created_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "conversation_participants_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversation_participants_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      conversations: {
        Row: {
          created_at: string
          created_by: string
          id: string
          last_message_at: string | null
          store_id: string
        }
        Insert: {
          created_at?: string
          created_by: string
          id?: string
          last_message_at?: string | null
          store_id: string
        }
        Update: {
          created_at?: string
          created_by?: string
          id?: string
          last_message_at?: string | null
          store_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "conversations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversations_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "customer_stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversations_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      delivery_methods: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          name_ar: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name_ar: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name_ar?: string
        }
        Relationships: []
      }
      favorites: {
        Row: {
          created_at: string
          id: string
          product_id: string | null
          store_id: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          product_id?: string | null
          store_id?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          product_id?: string | null
          store_id?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "favorites_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "customer_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "favorites_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "favorites_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "customer_stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "favorites_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "favorites_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      handoff_options: {
        Row: {
          code: string
          created_at: string
          id: string
          is_active: boolean
          name_ar: string
          store_id: string
        }
        Insert: {
          code: string
          created_at?: string
          id?: string
          is_active?: boolean
          name_ar: string
          store_id: string
        }
        Update: {
          code?: string
          created_at?: string
          id?: string
          is_active?: boolean
          name_ar?: string
          store_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "handoff_options_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "customer_stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "handoff_options_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      honey_taxonomy: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          metadata: Json
          name_ar: string
          name_en: string | null
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          metadata?: Json
          name_ar: string
          name_en?: string | null
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          metadata?: Json
          name_ar?: string
          name_en?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      merchant_application_drafts: {
        Row: {
          certificate_note: string | null
          display_name: string
          experience: string
          location: string
          phone: string
          specialties: string
          updated_at: string
          user_id: string
        }
        Insert: {
          certificate_note?: string | null
          display_name?: string
          experience?: string
          location?: string
          phone?: string
          specialties?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          certificate_note?: string | null
          display_name?: string
          experience?: string
          location?: string
          phone?: string
          specialties?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "merchant_application_drafts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      merchant_applications: {
        Row: {
          certificate_note: string | null
          display_name: string
          experience: string
          id: string
          location: string
          phone: string
          review_note: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          specialties: string
          status: string
          submitted_at: string
          user_id: string
        }
        Insert: {
          certificate_note?: string | null
          display_name: string
          experience: string
          id?: string
          location: string
          phone: string
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          specialties: string
          status?: string
          submitted_at?: string
          user_id: string
        }
        Update: {
          certificate_note?: string | null
          display_name?: string
          experience?: string
          id?: string
          location?: string
          phone?: string
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          specialties?: string
          status?: string
          submitted_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "merchant_applications_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "merchant_applications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      merchant_delivery_options: {
        Row: {
          created_at: string
          currency: string
          delivery_method_id: string
          estimated_days: number | null
          fee_amount: number | null
          id: string
          is_active: boolean
          region_id: string | null
          store_id: string
        }
        Insert: {
          created_at?: string
          currency?: string
          delivery_method_id: string
          estimated_days?: number | null
          fee_amount?: number | null
          id?: string
          is_active?: boolean
          region_id?: string | null
          store_id: string
        }
        Update: {
          created_at?: string
          currency?: string
          delivery_method_id?: string
          estimated_days?: number | null
          fee_amount?: number | null
          id?: string
          is_active?: boolean
          region_id?: string | null
          store_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "merchant_delivery_options_delivery_method_id_fkey"
            columns: ["delivery_method_id"]
            isOneToOne: false
            referencedRelation: "delivery_methods"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "merchant_delivery_options_region_id_fkey"
            columns: ["region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "merchant_delivery_options_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "customer_stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "merchant_delivery_options_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      merchant_pickup_locations: {
        Row: {
          address: string | null
          created_at: string
          geo_lat: number | null
          geo_lng: number | null
          id: string
          is_active: boolean
          name_ar: string
          phone: string | null
          region_id: string | null
          store_id: string
          updated_at: string
        }
        Insert: {
          address?: string | null
          created_at?: string
          geo_lat?: number | null
          geo_lng?: number | null
          id?: string
          is_active?: boolean
          name_ar: string
          phone?: string | null
          region_id?: string | null
          store_id: string
          updated_at?: string
        }
        Update: {
          address?: string | null
          created_at?: string
          geo_lat?: number | null
          geo_lng?: number | null
          id?: string
          is_active?: boolean
          name_ar?: string
          phone?: string | null
          region_id?: string | null
          store_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "merchant_pickup_locations_region_id_fkey"
            columns: ["region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "merchant_pickup_locations_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "customer_stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "merchant_pickup_locations_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      merchant_profiles: {
        Row: {
          business_name: string
          created_at: string
          description: string | null
          legal_name: string | null
          updated_at: string
          user_id: string
          verification_status: string
          verified_at: string | null
        }
        Insert: {
          business_name: string
          created_at?: string
          description?: string | null
          legal_name?: string | null
          updated_at?: string
          user_id: string
          verification_status?: string
          verified_at?: string | null
        }
        Update: {
          business_name?: string
          created_at?: string
          description?: string | null
          legal_name?: string | null
          updated_at?: string
          user_id?: string
          verification_status?: string
          verified_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "merchant_profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      messages: {
        Row: {
          body: string
          conversation_id: string
          created_at: string
          id: string
          read_at: string | null
          sender_id: string
        }
        Insert: {
          body: string
          conversation_id: string
          created_at?: string
          id?: string
          read_at?: string | null
          sender_id: string
        }
        Update: {
          body?: string
          conversation_id?: string
          created_at?: string
          id?: string
          read_at?: string | null
          sender_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "messages_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "messages_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          body_ar: string | null
          created_at: string
          id: string
          notification_type: string
          payload: Json
          read_at: string | null
          title_ar: string
          user_id: string
        }
        Insert: {
          body_ar?: string | null
          created_at?: string
          id?: string
          notification_type: string
          payload?: Json
          read_at?: string | null
          title_ar: string
          user_id: string
        }
        Update: {
          body_ar?: string | null
          created_at?: string
          id?: string
          notification_type?: string
          payload?: Json
          read_at?: string | null
          title_ar?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      product_categories: {
        Row: {
          category_id: string
          product_id: string
        }
        Insert: {
          category_id: string
          product_id: string
        }
        Update: {
          category_id?: string
          product_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_categories_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_categories_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "customer_products"
            referencedColumns: ["category_id"]
          },
          {
            foreignKeyName: "product_categories_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "customer_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_categories_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      product_certifications: {
        Row: {
          certification_id: string
          product_id: string
        }
        Insert: {
          certification_id: string
          product_id: string
        }
        Update: {
          certification_id?: string
          product_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_certifications_certification_id_fkey"
            columns: ["certification_id"]
            isOneToOne: false
            referencedRelation: "certifications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_certifications_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "customer_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_certifications_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      product_images: {
        Row: {
          alt_text_ar: string | null
          created_at: string
          id: string
          image_url: string
          product_id: string
          sort_order: number
        }
        Insert: {
          alt_text_ar?: string | null
          created_at?: string
          id?: string
          image_url: string
          product_id: string
          sort_order?: number
        }
        Update: {
          alt_text_ar?: string | null
          created_at?: string
          id?: string
          image_url?: string
          product_id?: string
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "product_images_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "customer_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_images_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      product_likes: {
        Row: {
          created_at: string
          product_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          product_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          product_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_likes_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "customer_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_likes_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_likes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      product_view_events: {
        Row: {
          id: string
          product_id: string
          viewed_at: string
          viewer_id: string | null
        }
        Insert: {
          id?: string
          product_id: string
          viewed_at?: string
          viewer_id?: string | null
        }
        Update: {
          id?: string
          product_id?: string
          viewed_at?: string
          viewer_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "product_view_events_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "customer_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_view_events_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_view_events_viewer_id_fkey"
            columns: ["viewer_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      products: {
        Row: {
          created_at: string
          description: string | null
          grade_level: number | null
          id: string
          is_featured: boolean
          metadata: Json
          name_ar: string
          name_en: string | null
          product_type: string
          status: string
          store_id: string
          taxonomy_id: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          grade_level?: number | null
          id?: string
          is_featured?: boolean
          metadata?: Json
          name_ar: string
          name_en?: string | null
          product_type?: string
          status?: string
          store_id: string
          taxonomy_id?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          grade_level?: number | null
          id?: string
          is_featured?: boolean
          metadata?: Json
          name_ar?: string
          name_en?: string | null
          product_type?: string
          status?: string
          store_id?: string
          taxonomy_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "products_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "customer_stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "products_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "products_taxonomy_id_fkey"
            columns: ["taxonomy_id"]
            isOneToOne: false
            referencedRelation: "honey_taxonomy"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          bio: string | null
          created_at: string
          display_name: string
          is_active: boolean
          locale: string
          phone: string | null
          role: string
          updated_at: string
          user_id: string
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string
          display_name?: string
          is_active?: boolean
          locale?: string
          phone?: string | null
          role?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string
          display_name?: string
          is_active?: boolean
          locale?: string
          phone?: string | null
          role?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      regions: {
        Row: {
          code: string | null
          created_at: string
          id: string
          is_active: boolean
          name_ar: string
          name_ar_normalized: string | null
          name_en: string | null
          name_en_normalized: string | null
          parent_region_id: string | null
          region_level: string
        }
        Insert: {
          code?: string | null
          created_at?: string
          id?: string
          is_active?: boolean
          name_ar: string
          name_ar_normalized?: string | null
          name_en?: string | null
          name_en_normalized?: string | null
          parent_region_id?: string | null
          region_level?: string
        }
        Update: {
          code?: string | null
          created_at?: string
          id?: string
          is_active?: boolean
          name_ar?: string
          name_ar_normalized?: string | null
          name_en?: string | null
          name_en_normalized?: string | null
          parent_region_id?: string | null
          region_level?: string
        }
        Relationships: [
          {
            foreignKeyName: "regions_parent_region_id_fkey"
            columns: ["parent_region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
        ]
      }
      request_items: {
        Row: {
          note: string | null
          product_id: string
          quantity: number
          request_id: string
        }
        Insert: {
          note?: string | null
          product_id: string
          quantity?: number
          request_id: string
        }
        Update: {
          note?: string | null
          product_id?: string
          quantity?: number
          request_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "request_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "customer_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "request_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "request_items_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "requests"
            referencedColumns: ["id"]
          },
        ]
      }
      request_messages: {
        Row: {
          body: string
          created_at: string
          id: string
          request_id: string
          sender_id: string
        }
        Insert: {
          body: string
          created_at?: string
          id?: string
          request_id: string
          sender_id: string
        }
        Update: {
          body?: string
          created_at?: string
          id?: string
          request_id?: string
          sender_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "request_messages_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "requests"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "request_messages_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      requests: {
        Row: {
          body: string | null
          contact_channel: string | null
          created_at: string
          delivery_note: string | null
          handoff_details: Json
          id: string
          phone: string | null
          preferred_handoff_option: string | null
          price_note: string | null
          requester_id: string
          status: string
          store_id: string
          subject: string
          updated_at: string
        }
        Insert: {
          body?: string | null
          contact_channel?: string | null
          created_at?: string
          delivery_note?: string | null
          handoff_details?: Json
          id?: string
          phone?: string | null
          preferred_handoff_option?: string | null
          price_note?: string | null
          requester_id: string
          status?: string
          store_id: string
          subject: string
          updated_at?: string
        }
        Update: {
          body?: string | null
          contact_channel?: string | null
          created_at?: string
          delivery_note?: string | null
          handoff_details?: Json
          id?: string
          phone?: string | null
          preferred_handoff_option?: string | null
          price_note?: string | null
          requester_id?: string
          status?: string
          store_id?: string
          subject?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "requests_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "requests_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "customer_stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "requests_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      review_likes: {
        Row: {
          created_at: string
          review_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          review_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          review_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "review_likes_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "reviews"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "review_likes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      reviews: {
        Row: {
          author_id: string
          body: string | null
          created_at: string
          id: string
          product_id: string
          rating: number
          status: string
          store_id: string
          updated_at: string
        }
        Insert: {
          author_id: string
          body?: string | null
          created_at?: string
          id?: string
          product_id: string
          rating: number
          status?: string
          store_id: string
          updated_at?: string
        }
        Update: {
          author_id?: string
          body?: string | null
          created_at?: string
          id?: string
          product_id?: string
          rating?: number
          status?: string
          store_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "reviews_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "customer_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "customer_stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      social_links: {
        Row: {
          created_at: string
          id: string
          platform: string
          store_id: string
          url: string
        }
        Insert: {
          created_at?: string
          id?: string
          platform: string
          store_id: string
          url: string
        }
        Update: {
          created_at?: string
          id?: string
          platform?: string
          store_id?: string
          url?: string
        }
        Relationships: [
          {
            foreignKeyName: "social_links_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "customer_stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "social_links_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      store_followers: {
        Row: {
          created_at: string
          store_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          store_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          store_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "store_followers_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "customer_stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "store_followers_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "store_followers_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      store_gallery: {
        Row: {
          alt_text_ar: string | null
          created_at: string
          id: string
          media_url: string
          sort_order: number
          store_id: string
        }
        Insert: {
          alt_text_ar?: string | null
          created_at?: string
          id?: string
          media_url: string
          sort_order?: number
          store_id: string
        }
        Update: {
          alt_text_ar?: string | null
          created_at?: string
          id?: string
          media_url?: string
          sort_order?: number
          store_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "store_gallery_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "customer_stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "store_gallery_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      store_statistics: {
        Row: {
          followers_count: number
          product_count: number
          rating_average: number
          review_count: number
          store_id: string
          updated_at: string
        }
        Insert: {
          followers_count?: number
          product_count?: number
          rating_average?: number
          review_count?: number
          store_id: string
          updated_at?: string
        }
        Update: {
          followers_count?: number
          product_count?: number
          rating_average?: number
          review_count?: number
          store_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "store_statistics_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: true
            referencedRelation: "customer_stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "store_statistics_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: true
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      stores: {
        Row: {
          cover_url: string | null
          created_at: string
          description: string | null
          id: string
          is_verified: boolean
          logo_url: string | null
          merchant_id: string
          name_ar: string
          phone: string | null
          region_id: string | null
          slug: string
          status: string
          updated_at: string
        }
        Insert: {
          cover_url?: string | null
          created_at?: string
          description?: string | null
          id?: string
          is_verified?: boolean
          logo_url?: string | null
          merchant_id: string
          name_ar: string
          phone?: string | null
          region_id?: string | null
          slug: string
          status?: string
          updated_at?: string
        }
        Update: {
          cover_url?: string | null
          created_at?: string
          description?: string | null
          id?: string
          is_verified?: boolean
          logo_url?: string | null
          merchant_id?: string
          name_ar?: string
          phone?: string | null
          region_id?: string | null
          slug?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "stores_merchant_id_fkey"
            columns: ["merchant_id"]
            isOneToOne: false
            referencedRelation: "merchant_profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "stores_region_id_fkey"
            columns: ["region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
        ]
      }
      users: {
        Row: {
          created_at: string
          id: string
          last_seen_at: string | null
        }
        Insert: {
          created_at?: string
          id: string
          last_seen_at?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          last_seen_at?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      customer_banners: {
        Row: {
          created_at: string | null
          cta_label_ar: string | null
          description_ar: string | null
          ends_at: string | null
          id: string | null
          image_url: string | null
          is_active: boolean | null
          sort_order: number | null
          starts_at: string | null
          target_query: string | null
          title_ar: string | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          cta_label_ar?: never
          description_ar?: string | null
          ends_at?: string | null
          id?: string | null
          image_url?: string | null
          is_active?: boolean | null
          sort_order?: number | null
          starts_at?: string | null
          target_query?: string | null
          title_ar?: string | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          cta_label_ar?: never
          description_ar?: string | null
          ends_at?: string | null
          id?: string | null
          image_url?: string | null
          is_active?: boolean | null
          sort_order?: number | null
          starts_at?: string | null
          target_query?: string | null
          title_ar?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      customer_products: {
        Row: {
          availability: string | null
          badges: string[] | null
          category_id: string | null
          category_name_ar: string | null
          certifications: string[] | null
          created_at: string | null
          currency_code: string | null
          delivery_options: string[] | null
          description: string | null
          forms: string[] | null
          grade_label_ar: string | null
          grade_level: number | null
          harvest_label: string | null
          honey_identity: string | null
          id: string | null
          image_urls: string[] | null
          is_featured: boolean | null
          likes_count: number | null
          merchant_id: string | null
          metadata: Json | null
          name_ar: string | null
          name_en: string | null
          origin_country: string | null
          packaged_date: string | null
          packaging_label_ar: string | null
          pickup_locations: string[] | null
          price: number | null
          primary_image_url: string | null
          processing_method_ar: string | null
          processing_status_ar: string | null
          product_type: string | null
          production_date: string | null
          province_id: string | null
          province_name_ar: string | null
          purpose: string | null
          quality_label_ar: string | null
          rating_average: number | null
          region_id: string | null
          region_name_ar: string | null
          regions: string[] | null
          review_count: number | null
          status: string | null
          store_id: string | null
          subcategory_id: string | null
          subcategory_name_ar: string | null
          tags: string[] | null
          taxonomy_id: string | null
          updated_at: string | null
          views_count: number | null
          weight_label: string | null
        }
        Relationships: [
          {
            foreignKeyName: "products_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "customer_stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "products_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "products_taxonomy_id_fkey"
            columns: ["subcategory_id"]
            isOneToOne: false
            referencedRelation: "honey_taxonomy"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "products_taxonomy_id_fkey"
            columns: ["taxonomy_id"]
            isOneToOne: false
            referencedRelation: "honey_taxonomy"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "stores_merchant_id_fkey"
            columns: ["merchant_id"]
            isOneToOne: false
            referencedRelation: "merchant_profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      customer_stores: {
        Row: {
          avatar_url: string | null
          bio: string | null
          certifications: string[] | null
          contact_phone: string | null
          contact_telegram: string | null
          contact_whatsapp: string | null
          cover_url: string | null
          delivery_options: string[] | null
          description: string | null
          followers_count: number | null
          gallery_urls: string[] | null
          id: string | null
          is_verified: boolean | null
          logo_url: string | null
          merchant_id: string | null
          merchant_name_ar: string | null
          name_ar: string | null
          pickup_locations: string[] | null
          rating_average: number | null
          region_id: string | null
          region_name_ar: string | null
          review_count: number | null
          slug: string | null
          social_links: Json | null
          specialties: string[] | null
          status: string | null
          years_experience: number | null
        }
        Relationships: [
          {
            foreignKeyName: "stores_merchant_id_fkey"
            columns: ["merchant_id"]
            isOneToOne: false
            referencedRelation: "merchant_profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "stores_region_id_fkey"
            columns: ["region_id"]
            isOneToOne: false
            referencedRelation: "regions"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      delete_my_account: { Args: never; Returns: undefined }
      has_admin_permission: {
        Args: { permission_code: string }
        Returns: boolean
      }
      is_admin: { Args: never; Returns: boolean }
      is_super_admin: { Args: never; Returns: boolean }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
